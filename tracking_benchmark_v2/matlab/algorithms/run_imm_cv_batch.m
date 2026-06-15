function result = run_imm_cv_batch(measurements, ~, alg_cfg, cfg)
%RUN_IMM_CV_BATCH IMM with multiple constant-velocity models.

dt = cfg.scenario.dt;
R = measurements.R;
q_list = alg_cfg.q_list;
num_models = numel(q_list);
transition_matrix = alg_cfg.transition_matrix;

F_models = zeros(4, 4, num_models);
Q_models = zeros(4, 4, num_models);
H = [];
for model_index = 1:num_models
    [F, Q, ~, H] = discrete_cv_model(dt, q_list(model_index));
    F_models(:, :, model_index) = F;
    Q_models(:, :, model_index) = Q;
end

I = eye(4);
num_steps = size(measurements.z, 2);
num_trials = size(measurements.z, 3);
result = initialize_algorithm_result(num_steps, num_trials);
result.model_probabilities = zeros(num_models, num_steps, num_trials);
result.mode_index = zeros(1, num_steps, num_trials);

for trial = 1:num_trials
    x_models = repmat(alg_cfg.x0, 1, num_models);
    P_models = repmat(alg_cfg.P0, 1, 1, num_models);
    mu = alg_cfg.mu0(:);

    for k = 1:num_steps
        if cfg.experiment.use_known_initial_state && k == 1
            x_combined = x_models * mu;
            P_combined = combine_model_covariances(x_models, P_models, mu, x_combined);
            state_ca = cv_to_ca_state(x_combined);

            result.state_estimates(:, k, trial) = state_ca;
            result.position_estimates(:, k, trial) = state_ca([1, 4]);
            result.model_probabilities(:, k, trial) = mu;
            result.mode_index(1, k, trial) = argmax_index(mu);

            if trial == 1
                result.state_covariances_first(:, :, k) = cv_to_ca_covariance(P_combined, 0);
            end
            continue;
        end

        c_bar = max(transition_matrix' * mu, realmin);
        x_mixed = zeros(4, num_models);
        P_mixed = zeros(4, 4, num_models);

        for j = 1:num_models
            mixing_weights = transition_matrix(:, j) .* mu ./ c_bar(j);
            x_mixed(:, j) = x_models * mixing_weights;

            for i = 1:num_models
                delta_state = x_models(:, i) - x_mixed(:, j);
                P_mixed(:, :, j) = P_mixed(:, :, j) + ...
                    mixing_weights(i) * (P_models(:, :, i) + delta_state * delta_state');
            end
        end

        likelihoods = zeros(num_models, 1);
        nis_values = zeros(num_models, 1);
        for j = 1:num_models
            x_current = x_mixed(:, j);
            P_current = ensure_symmetric_psd(P_mixed(:, :, j));

            if k > 1
                x_current = F_models(:, :, j) * x_current;
                P_current = F_models(:, :, j) * P_current * F_models(:, :, j)' + Q_models(:, :, j);
            end

            innovation = measurements.z(:, k, trial) - H * x_current;
            S = H * P_current * H' + R;
            K = (P_current * H') / S;

            x_models(:, j) = x_current + K * innovation;
            correction = I - K * H;
            P_models(:, :, j) = correction * P_current * correction' + K * R * K';
            P_models(:, :, j) = ensure_symmetric_psd(P_models(:, :, j));

            likelihoods(j) = gaussian_likelihood(innovation, S);
            nis_values(j) = max(innovation' * (S \ innovation), 0);
        end

        mu = c_bar .* likelihoods;
        mu_sum = sum(mu);
        if mu_sum <= realmin
            mu = ones(num_models, 1) / num_models;
        else
            mu = mu / mu_sum;
        end

        x_combined = x_models * mu;
        P_combined = combine_model_covariances(x_models, P_models, mu, x_combined);
        state_ca = cv_to_ca_state(x_combined);

        result.state_estimates(:, k, trial) = state_ca;
        result.position_estimates(:, k, trial) = state_ca([1, 4]);
        result.model_probabilities(:, k, trial) = mu;
        result.mode_index(1, k, trial) = argmax_index(mu);
        result.innovation_norm(1, k, trial) = sqrt(mu' * nis_values);

        if trial == 1
            result.state_covariances_first(:, :, k) = cv_to_ca_covariance(P_combined, 0);
        end
    end
end
end

function P_combined = combine_model_covariances(x_models, P_models, mu, x_combined)
num_models = numel(mu);
P_combined = zeros(size(P_models, 1), size(P_models, 2));

for j = 1:num_models
    delta_state = x_models(:, j) - x_combined;
    P_combined = P_combined + mu(j) * (P_models(:, :, j) + delta_state * delta_state');
end

P_combined = ensure_symmetric_psd(P_combined);
end

function index = argmax_index(values)
[~, index] = max(values);
end
