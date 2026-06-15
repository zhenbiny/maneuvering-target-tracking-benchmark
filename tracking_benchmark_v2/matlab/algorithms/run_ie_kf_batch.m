function result = run_ie_kf_batch(measurements, ~, alg_cfg, cfg)
%RUN_IE_KF_BATCH Windowed Bayesian input-estimation tracker.

dt = cfg.scenario.dt;
R = measurements.R;
process_covariance = local_process_covariance(dt, alg_cfg.q);

num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);
result = initialize_algorithm_result(num_steps, num_trials);
result.input_estimates = zeros(2, num_steps, num_trials);
result.detector_score = zeros(1, num_steps, num_trials);
result.mode_probability = zeros(2, num_steps, num_trials);
result.mode_index = zeros(1, num_steps, num_trials);

initial_state = [alg_cfg.x0(1); alg_cfg.x0(2); 0; alg_cfg.x0(3); alg_cfg.x0(4); 0];
initial_covariance = zeros(6);
initial_covariance([1, 2, 4, 5], [1, 2, 4, 5]) = alg_cfg.P0;
initial_covariance(3, 3) = alg_cfg.initial_acceleration_std^2;
initial_covariance(6, 6) = alg_cfg.initial_acceleration_std^2;
initial_covariance = ensure_symmetric_psd(initial_covariance);

for trial = 1:num_trials
    maneuver_flag = false;
    on_count = 0;
    off_count = 0;

    state_history = zeros(6, num_steps);
    covariance_history = zeros(6, 6, num_steps);
    state_history(:, 1) = initial_state;
    covariance_history(:, :, 1) = initial_covariance;

    for k = 1:num_steps
        if cfg.experiment.use_known_initial_state && k == 1
            result.state_estimates(:, k, trial) = initial_state;
            result.position_estimates(:, k, trial) = initial_state([1, 4]);
            result.input_estimates(:, k, trial) = [0; 0];
            result.mode_probability(:, k, trial) = [1; 0];
            result.mode_index(1, k, trial) = 1;
            if trial == 1
                result.state_covariances_first(:, :, k) = initial_covariance;
            end
            continue;
        end

        start_index = max(2, k - alg_cfg.window_length + 1);
        prior_state = state_history(:, start_index - 1);
        prior_state([3, 6]) = alg_cfg.acceleration_decay * prior_state([3, 6]);
        prior_covariance = covariance_history(:, :, start_index - 1) + process_covariance;
        prior_covariance = ensure_symmetric_psd(prior_covariance);

        measurement_window = measurements.z(:, start_index:k, trial);
        [current_state, current_covariance] = estimate_window_state( ...
            measurement_window, prior_state, prior_covariance, R, dt, alg_cfg);

        detector_score = sqrt( ...
            current_state(3)^2 / max(current_covariance(3, 3), 1.0e-10) + ...
            current_state(6)^2 / max(current_covariance(6, 6), 1.0e-10));

        if maneuver_flag
            if detector_score <= alg_cfg.threshold_off
                off_count = off_count + 1;
            else
                off_count = 0;
            end
            if off_count >= alg_cfg.evidence_count_off
                maneuver_flag = false;
                off_count = 0;
                on_count = 0;
            end
        else
            if detector_score >= alg_cfg.threshold_on
                on_count = on_count + 1;
            else
                on_count = max(on_count - 1, 0);
            end
            if on_count >= alg_cfg.evidence_count_on
                maneuver_flag = true;
                on_count = 0;
                off_count = 0;
            end
        end

        if ~maneuver_flag
            current_state([3, 6]) = alg_cfg.acceleration_decay * current_state([3, 6]);
        end

        state_history(:, k) = current_state;
        covariance_history(:, :, k) = current_covariance;

        result.state_estimates(:, k, trial) = current_state;
        result.position_estimates(:, k, trial) = current_state([1, 4]);
        result.input_estimates(:, k, trial) = current_state([3, 6]);
        result.detector_score(1, k, trial) = detector_score;
        result.mode_probability(:, k, trial) = [double(~maneuver_flag); double(maneuver_flag)];
        result.mode_index(1, k, trial) = 1 + double(maneuver_flag);
        result.innovation_norm(1, k, trial) = detector_score;

        if trial == 1
            result.state_covariances_first(:, :, k) = current_covariance;
        end
    end
end
end

function [current_state, current_covariance] = estimate_window_state( ...
    measurement_window, prior_state, prior_covariance, R, dt, alg_cfg)
window_count = size(measurement_window, 2);
stacked_measurements = zeros(2 * window_count, 1);
stacked_observation = zeros(2 * window_count, 6);
stacked_covariance = zeros(2 * window_count);

weights = alg_cfg.acceleration_decay .^ ((window_count - 1):-1:0);

for step_index = 1:window_count
    tau = step_index * dt;
    row_range = (2 * step_index - 1):(2 * step_index);

    stacked_measurements(row_range) = measurement_window(:, step_index);
    stacked_observation(row_range, :) = [
        1, tau, 0.5 * tau^2, 0, 0, 0;
        0, 0, 0, 1, tau, 0.5 * tau^2
    ];
    stacked_covariance(row_range, row_range) = R / max(weights(step_index), 1.0e-6);
end

prior_precision = prior_covariance \ eye(6);
regularization = alg_cfg.regularization * diag([0, 0, 1, 0, 0, 1]);
posterior_precision = prior_precision + ...
    stacked_observation' * (stacked_covariance \ stacked_observation) + ...
    regularization;
posterior_covariance_start = ensure_symmetric_psd(posterior_precision \ eye(6));
posterior_state_start = posterior_covariance_start * ( ...
    prior_precision * prior_state + ...
    stacked_observation' * (stacked_covariance \ stacked_measurements));

posterior_state_start([3, 6]) = clip_vector( ...
    posterior_state_start([3, 6]), alg_cfg.max_abs_input);

tau_end = window_count * dt;
transition_to_current = [
    1, tau_end, 0.5 * tau_end^2, 0, 0, 0;
    0, 1, tau_end, 0, 0, 0;
    0, 0, 1, 0, 0, 0;
    0, 0, 0, 1, tau_end, 0.5 * tau_end^2;
    0, 0, 0, 0, 1, tau_end;
    0, 0, 0, 0, 0, 1
];

current_state = transition_to_current * posterior_state_start;
current_covariance = ensure_symmetric_psd( ...
    transition_to_current * posterior_covariance_start * transition_to_current');
end

function process_covariance = local_process_covariance(dt, q)
q_axis = q * [
    dt^5 / 20, dt^4 / 8, dt^3 / 6;
    dt^4 / 8, dt^3 / 3, dt^2 / 2;
    dt^3 / 6, dt^2 / 2, dt
];
process_covariance = blkdiag(q_axis, q_axis);
end

function clipped = clip_vector(vector_in, max_abs_value)
clipped = min(max(vector_in, -max_abs_value), max_abs_value);
end
