function result = run_ca_kf_batch(measurements, ~, alg_cfg, cfg)
%RUN_CA_KF_BATCH Constant-acceleration Kalman filter baseline.

[F, Q, H] = discrete_ca_model(cfg.scenario.dt, alg_cfg.q);
I = eye(6);
R = measurements.R;

num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);
result = initialize_algorithm_result(num_steps, num_trials);

for trial = 1:num_trials
    x_hat = alg_cfg.x0;
    P_hat = alg_cfg.P0;

    for k = 1:num_steps
        if cfg.experiment.use_known_initial_state && k == 1
            result.state_estimates(:, k, trial) = x_hat;
            result.position_estimates(:, k, trial) = x_hat([1, 4]);
            if trial == 1
                result.state_covariances_first(:, :, k) = P_hat;
            end
            continue;
        end

        if k > 1
            x_pred = F * x_hat;
            P_pred = F * P_hat * F' + Q;
        else
            x_pred = x_hat;
            P_pred = P_hat;
        end

        innovation = measurements.z(:, k, trial) - H * x_pred;
        S = H * P_pred * H' + R;
        K = (P_pred * H') / S;

        x_hat = x_pred + K * innovation;
        correction = I - K * H;
        P_hat = correction * P_pred * correction' + K * R * K';
        P_hat = ensure_symmetric_psd(P_hat);

        result.state_estimates(:, k, trial) = x_hat;
        result.position_estimates(:, k, trial) = x_hat([1, 4]);
        result.innovation_norm(1, k, trial) = sqrt(max(innovation' * (S \ innovation), 0));

        if trial == 1
            result.state_covariances_first(:, :, k) = P_hat;
        end
    end
end
end
