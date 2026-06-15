function result = run_vd_kf_batch(measurements, ~, alg_cfg, cfg)
%RUN_VD_KF_BATCH Parallel-filter variable-dimension maneuver tracker.

[F_cv, Q_cv, ~, H_cv] = discrete_cv_model(cfg.scenario.dt, alg_cfg.cv_q);
[F_ca, Q_ca, H_ca] = discrete_ca_model(cfg.scenario.dt, alg_cfg.ca_q);
I_cv = eye(4);
I_ca = eye(6);
R = measurements.R;

num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);
result = initialize_algorithm_result(num_steps, num_trials);
result.detector_score = zeros(1, num_steps, num_trials);
result.mode_probability = zeros(2, num_steps, num_trials);
result.mode_index = zeros(1, num_steps, num_trials);

for trial = 1:num_trials
    mode = 1;
    x_cv = alg_cfg.cv_x0;
    P_cv = alg_cfg.cv_P0;
    x_ca = alg_cfg.ca_x0;
    P_ca = alg_cfg.ca_P0;
    score_ema = 0;
    quiet_count = 0;

    for k = 1:num_steps
        if cfg.experiment.use_known_initial_state && k == 1
            state_ca = cv_to_ca_state(x_cv);
            result.state_estimates(:, k, trial) = state_ca;
            result.position_estimates(:, k, trial) = state_ca([1, 4]);
            result.mode_probability(:, k, trial) = [1; 0];
            result.mode_index(1, k, trial) = 1;
            if trial == 1
                result.state_covariances_first(:, :, k) = ...
                    cv_to_ca_covariance(P_cv, alg_cfg.inserted_acceleration_variance);
            end
            continue;
        end

        if k > 1
            x_cv_pred = F_cv * x_cv;
            P_cv_pred = F_cv * P_cv * F_cv' + Q_cv;
        else
            x_cv_pred = x_cv;
            P_cv_pred = P_cv;
        end

        innovation_cv = measurements.z(:, k, trial) - H_cv * x_cv_pred;
        S_cv = H_cv * P_cv_pred * H_cv' + R;
        nis_cv = max(innovation_cv' * (S_cv \ innovation_cv), 0);
        K_cv = (P_cv_pred * H_cv') / S_cv;
        x_cv = x_cv_pred + K_cv * innovation_cv;
        correction_cv = I_cv - K_cv * H_cv;
        P_cv = correction_cv * P_cv_pred * correction_cv' + K_cv * R * K_cv';
        P_cv = ensure_symmetric_psd(P_cv);

        if k > 1
            x_ca_pred = F_ca * x_ca;
            P_ca_pred = F_ca * P_ca * F_ca' + Q_ca;
        else
            x_ca_pred = x_ca;
            P_ca_pred = P_ca;
        end

        innovation_ca = measurements.z(:, k, trial) - H_ca * x_ca_pred;
        S_ca = H_ca * P_ca_pred * H_ca' + R;
        nis_ca = max(innovation_ca' * (S_ca \ innovation_ca), 0);
        K_ca = (P_ca_pred * H_ca') / S_ca;
        x_ca = x_ca_pred + K_ca * innovation_ca;
        correction_ca = I_ca - K_ca * H_ca;
        P_ca = correction_ca * P_ca_pred * correction_ca' + K_ca * R * K_ca';
        P_ca = ensure_symmetric_psd(P_ca);

        nis_cv_sqrt = sqrt(nis_cv);
        nis_ca_sqrt = sqrt(nis_ca);
        score_inst = nis_cv_sqrt - nis_ca_sqrt;
        score_ema = alg_cfg.innovation_ema * score_ema + ...
            (1 - alg_cfg.innovation_ema) * score_inst;

        accel_score = sqrt( ...
            x_ca(3)^2 / max(P_ca(3, 3), 1.0e-10) + ...
            x_ca(6)^2 / max(P_ca(6, 6), 1.0e-10));

        if mode == 1
            cv_embedded = cv_to_ca_state(x_cv);
            x_ca([1, 2, 4, 5]) = ...
                alg_cfg.shadow_sync_ratio * x_ca([1, 2, 4, 5]) + ...
                (1 - alg_cfg.shadow_sync_ratio) * cv_embedded([1, 2, 4, 5]);
            x_ca([3, 6]) = alg_cfg.shadow_accel_decay * x_ca([3, 6]);
            P_ca = ensure_symmetric_psd( ...
                alg_cfg.shadow_sync_ratio * P_ca + ...
                (1 - alg_cfg.shadow_sync_ratio) * ...
                cv_to_ca_covariance(P_cv, alg_cfg.inserted_acceleration_variance));

            should_switch_up = score_ema >= alg_cfg.switch_up_threshold || ...
                (nis_cv_sqrt >= alg_cfg.switch_up_nis_threshold && ...
                score_inst >= alg_cfg.switch_advantage_margin);

            if should_switch_up
                mode = 2;
                quiet_count = 0;
            end
        else
            can_release = accel_score <= alg_cfg.accel_release_threshold && ...
                score_ema <= alg_cfg.switch_down_threshold && ...
                score_inst <= alg_cfg.switch_back_advantage && ...
                nis_cv_sqrt <= nis_ca_sqrt + alg_cfg.switch_back_advantage;

            if can_release
                quiet_count = quiet_count + 1;
            else
                quiet_count = 0;
            end

            if quiet_count >= alg_cfg.exit_hold_steps
                mode = 1;
                quiet_count = 0;
                x_cv = 0.5 * x_cv + 0.5 * ca_to_cv_state(x_ca);
                P_cv = ensure_symmetric_psd( ...
                    0.5 * P_cv + 0.5 * ca_to_cv_covariance(P_ca));
                score_ema = min(score_ema, 0);
            end
        end

        if mode == 1
            state_ca = cv_to_ca_state(x_cv);
            state_covariance = cv_to_ca_covariance(P_cv, alg_cfg.inserted_acceleration_variance);
            active_nis = nis_cv_sqrt;
        else
            state_ca = x_ca;
            state_covariance = P_ca;
            active_nis = nis_ca_sqrt;
        end

        result.state_estimates(:, k, trial) = state_ca;
        result.position_estimates(:, k, trial) = state_ca([1, 4]);
        result.mode_probability(:, k, trial) = [double(mode == 1); double(mode == 2)];
        result.mode_index(1, k, trial) = mode;
        result.detector_score(1, k, trial) = score_ema;
        result.innovation_norm(1, k, trial) = active_nis;

        if trial == 1
            result.state_covariances_first(:, :, k) = state_covariance;
        end
    end
end
end
