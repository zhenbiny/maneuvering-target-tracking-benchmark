function result = run_imm_cv_batch(measurements, cfg)
%RUN_IMM_CV_BATCH IMM with three constant-velocity models.

dt = cfg.dt;
f_axis = [1, dt; 0, 1];
f_matrix = blkdiag(f_axis, f_axis);
h_matrix = [
    1, 0, 0, 0;
    0, 0, 1, 0
];
i_matrix = eye(4);
r_matrix = measurements.R;

q_list = cfg.imm.q_list;
num_models = numel(q_list);
q_matrices = zeros(4, 4, num_models);
for model_index = 1:num_models
    q_axis = q_list(model_index) * [
        dt^3 / 3, dt^2 / 2;
        dt^2 / 2, dt
    ];
    q_matrices(:, :, model_index) = blkdiag(q_axis, q_axis);
end

transition_matrix = cfg.imm.transition_matrix;
num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);

state_estimates = zeros(4, num_steps, num_trials);
model_probabilities = zeros(num_models, num_steps, num_trials);

for trial = 1:num_trials
    x_models = repmat(cfg.imm.x0, 1, num_models);
    p_models = repmat(cfg.imm.P0, 1, 1, num_models);
    mu = cfg.imm.mu0;

    for k = 1:num_steps
        if cfg.use_known_initial_state && k == 1
            state_estimates(:, k, trial) = x_models * mu;
            model_probabilities(:, k, trial) = mu;
            continue;
        end

        c_bar = max(transition_matrix' * mu, realmin);
        x_mixed = zeros(4, num_models);
        p_mixed = zeros(4, 4, num_models);

        for j = 1:num_models
            mixing_weights = transition_matrix(:, j) .* mu ./ c_bar(j);
            x_mixed(:, j) = x_models * mixing_weights;

            for i = 1:num_models
                delta_state = x_models(:, i) - x_mixed(:, j);
                p_mixed(:, :, j) = p_mixed(:, :, j) ...
                    + mixing_weights(i) * ...
                    (p_models(:, :, i) + delta_state * delta_state');
            end
        end

        likelihoods = zeros(num_models, 1);
        for j = 1:num_models
            x_current = x_mixed(:, j);
            p_current = p_mixed(:, :, j);

            if k > 1
                x_current = f_matrix * x_current;
                p_current = f_matrix * p_current * f_matrix' + q_matrices(:, :, j);
            end

            innovation = measurements.z(:, k, trial) - h_matrix * x_current;
            innovation_covariance = h_matrix * p_current * h_matrix' + r_matrix;
            kalman_gain = (p_current * h_matrix') / innovation_covariance;

            x_models(:, j) = x_current + kalman_gain * innovation;
            correction = i_matrix - kalman_gain * h_matrix;
            p_models(:, :, j) = correction * p_current * correction' ...
                + kalman_gain * r_matrix * kalman_gain';
            p_models(:, :, j) = 0.5 * (p_models(:, :, j) + p_models(:, :, j)');

            likelihoods(j) = gaussian_likelihood(innovation, innovation_covariance);
        end

        mu = c_bar .* likelihoods;
        mu_sum = sum(mu);
        if mu_sum <= realmin
            mu = ones(num_models, 1) / num_models;
        else
            mu = mu / mu_sum;
        end

        x_combined = x_models * mu;
        state_estimates(:, k, trial) = x_combined;
        model_probabilities(:, k, trial) = mu;
    end
end

result = struct();
result.scheme_name = 'IMM-CV';
result.state_estimates = state_estimates;
result.position_estimates = state_estimates([1, 3], :, :);
result.model_probabilities = model_probabilities;
end
