function result = run_singer_kf_batch(measurements, ~, alg_cfg, cfg)
%RUN_SINGER_KF_BATCH Singer model Kalman filter with optional RTS smoothing.

[F, Q, H] = discrete_singer_model(cfg.scenario.dt, alg_cfg.tau, alg_cfg.sigma_a);
I = eye(6);
R = measurements.R;

num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);
result = initialize_algorithm_result(num_steps, num_trials);

for trial = 1:num_trials
    x_hat = alg_cfg.x0;
    P_hat = alg_cfg.P0;

    state_filtered = zeros(6, num_steps);
    state_predicted = zeros(6, num_steps);
    covariance_filtered = zeros(6, 6, num_steps);
    covariance_predicted = zeros(6, 6, num_steps);
    innovation_norm = zeros(1, num_steps);

    for k = 1:num_steps
        if cfg.experiment.use_known_initial_state && k == 1
            state_filtered(:, k) = x_hat;
            state_predicted(:, k) = x_hat;
            covariance_filtered(:, :, k) = P_hat;
            covariance_predicted(:, :, k) = P_hat;
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

        state_predicted(:, k) = x_pred;
        covariance_predicted(:, :, k) = ensure_symmetric_psd(P_pred);
        state_filtered(:, k) = x_hat;
        covariance_filtered(:, :, k) = P_hat;
        innovation_norm(1, k) = sqrt(max(innovation' * (S \ innovation), 0));
    end

    if isfield(alg_cfg, 'use_rts_smoother') && alg_cfg.use_rts_smoother
        [state_sequence, covariance_sequence] = rts_smooth_sequence( ...
            F, state_filtered, covariance_filtered, state_predicted, covariance_predicted);
    else
        state_sequence = state_filtered;
        covariance_sequence = covariance_filtered;
    end

    result.state_estimates(:, :, trial) = state_sequence;
    result.position_estimates(:, :, trial) = state_sequence([1, 4], :);
    result.innovation_norm(1, :, trial) = innovation_norm;

    if trial == 1
        result.state_covariances_first = covariance_sequence;
    end
end
end
