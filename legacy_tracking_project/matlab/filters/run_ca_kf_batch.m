function result = run_ca_kf_batch(measurements, cfg)
%RUN_CA_KF_BATCH Constant-acceleration Kalman filter baseline.

dt = cfg.dt;
f_axis = [1, dt, 0.5 * dt^2; 0, 1, dt; 0, 0, 1];
q_axis = cfg.ca.q * [
    dt^5 / 20, dt^4 / 8, dt^3 / 6;
    dt^4 / 8, dt^3 / 3, dt^2 / 2;
    dt^3 / 6, dt^2 / 2, dt
];

f_matrix = blkdiag(f_axis, f_axis);
q_matrix = blkdiag(q_axis, q_axis);
h_matrix = [
    1, 0, 0, 0, 0, 0;
    0, 0, 0, 1, 0, 0
];
i_matrix = eye(6);
r_matrix = measurements.R;

num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);
state_estimates = zeros(6, num_steps, num_trials);

for trial = 1:num_trials
    x_hat = cfg.ca.x0;
    p_hat = cfg.ca.P0;

    for k = 1:num_steps
        if cfg.use_known_initial_state && k == 1
            state_estimates(:, k, trial) = x_hat;
            continue;
        end

        if k > 1
            x_hat = f_matrix * x_hat;
            p_hat = f_matrix * p_hat * f_matrix' + q_matrix;
        end

        innovation = measurements.z(:, k, trial) - h_matrix * x_hat;
        innovation_covariance = h_matrix * p_hat * h_matrix' + r_matrix;
        kalman_gain = (p_hat * h_matrix') / innovation_covariance;

        x_hat = x_hat + kalman_gain * innovation;
        correction = i_matrix - kalman_gain * h_matrix;
        p_hat = correction * p_hat * correction' + kalman_gain * r_matrix * kalman_gain';
        p_hat = 0.5 * (p_hat + p_hat');

        state_estimates(:, k, trial) = x_hat;
    end
end

result = struct();
result.scheme_name = 'CA-KF';
result.state_estimates = state_estimates;
result.position_estimates = state_estimates([1, 4], :, :);
end
