function [best_cfg, tuning] = select_singer_configuration(measurements, truth, cfg)
%SELECT_SINGER_CONFIGURATION Tune Singer-KF parameters over a compact grid.

base_cfg = cfg.algorithms.singer_kf;
candidates = build_singer_candidate_bank(base_cfg);
num_candidates = numel(candidates);

stage1_trials = min(base_cfg.tuning.stage1_trials, size(measurements.z, 3));
stage1_measurements = slice_measurements(measurements, 1:stage1_trials);
stage1_summaries = repmat(empty_summary(), num_candidates, 1);

for idx = 1:num_candidates
    batch = run_singer_kf_batch(stage1_measurements, truth, candidates(idx), cfg);
    evaluated = evaluate_estimates(batch, truth, cfg);
    stage1_summaries(idx) = build_tuning_summary( ...
        idx, candidates(idx).candidate_name, evaluated.metrics, cfg, stage1_trials);
end

stage1_order = rank_tuning_summaries(stage1_summaries);
top_count = min(base_cfg.tuning.full_eval_candidates, num_candidates);
top_indices = stage1_order(1:top_count);

full_summaries = repmat(empty_summary(), top_count, 1);
for rank_index = 1:top_count
    candidate_index = top_indices(rank_index);
    batch = run_singer_kf_batch(measurements, truth, candidates(candidate_index), cfg);
    evaluated = evaluate_estimates(batch, truth, cfg);
    full_summaries(rank_index) = build_tuning_summary( ...
        candidate_index, candidates(candidate_index).candidate_name, ...
        evaluated.metrics, cfg, size(measurements.z, 3));
end

full_order = rank_tuning_summaries(full_summaries);
selected_summary = full_summaries(full_order(1));
best_cfg = candidates(selected_summary.candidate_index);

tuning = struct();
tuning.stage1_trials = stage1_trials;
tuning.stage1_leaderboard = stage1_summaries(stage1_order(1:min(10, numel(stage1_order))));
tuning.full_leaderboard = full_summaries(full_order);
tuning.selected_candidate = selected_summary;
tuning.selected_parameters = struct( ...
    'tau', best_cfg.tau, ...
    'sigma_a', best_cfg.sigma_a, ...
    'accel_p0_std', sqrt(best_cfg.P0(3, 3)), ...
    'use_rts_smoother', best_cfg.use_rts_smoother);
end

function candidates = build_singer_candidate_bank(base_cfg)
tau_values = [20, 30, 45, 60, 90, 120];
sigma_values = [0.02, 0.04, 0.06, 0.08, 0.10, 0.14];
accel_p0_std_values = [0.01, 0.03, 0.06, 0.10];

num_candidates = numel(tau_values) * numel(sigma_values) * numel(accel_p0_std_values);
base_cfg.candidate_name = '';
candidates = repmat(base_cfg, num_candidates, 1);
candidate_index = 0;

for tau = tau_values
    for sigma_a = sigma_values
        for accel_p0_std = accel_p0_std_values
            candidate_index = candidate_index + 1;
            candidate = base_cfg;
            candidate.tau = tau;
            candidate.sigma_a = sigma_a;
            candidate.P0(3, 3) = accel_p0_std^2;
            candidate.P0(6, 6) = accel_p0_std^2;
            candidate.candidate_name = sprintf('tau=%.0f, sigma=%.3f, p0a=%.3f', ...
                tau, sigma_a, accel_p0_std);
            candidates(candidate_index) = candidate;
        end
    end
end
end

function summary = empty_summary()
summary = struct( ...
    'candidate_index', 0, ...
    'candidate_name', '', ...
    'used_trials', 0, ...
    'axis_non_maneuver', [inf, inf], ...
    'axis_maneuver', [inf, inf], ...
    'position_non_maneuver', inf, ...
    'position_maneuver', inf, ...
    'overall_position_rmse', inf, ...
    'non_excess', inf, ...
    'man_excess', inf, ...
    'pass_non', false, ...
    'pass_man', false, ...
    'pass_all', false, ...
    'score_vector', inf(1, 7));
end
