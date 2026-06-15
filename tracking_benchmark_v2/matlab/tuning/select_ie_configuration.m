function [best_cfg, tuning] = select_ie_configuration(measurements, truth, cfg)
%SELECT_IE_CONFIGURATION Tune the windowed IE tracker.

base_cfg = cfg.algorithms.ie_kf;
candidates = build_ie_candidate_bank(base_cfg);
num_candidates = numel(candidates);

stage1_trials = min(base_cfg.tuning.stage1_trials, size(measurements.z, 3));
stage1_measurements = slice_measurements(measurements, 1:stage1_trials);
stage1_summaries = repmat(empty_summary(), num_candidates, 1);

for idx = 1:num_candidates
    batch = run_ie_kf_batch(stage1_measurements, truth, candidates(idx), cfg);
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
    batch = run_ie_kf_batch(measurements, truth, candidates(candidate_index), cfg);
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
    'q', best_cfg.q, ...
    'window_length', best_cfg.window_length, ...
    'acceleration_decay', best_cfg.acceleration_decay, ...
    'initial_acceleration_std', best_cfg.initial_acceleration_std, ...
    'max_abs_input', best_cfg.max_abs_input, ...
    'threshold_on', best_cfg.threshold_on, ...
    'threshold_off', best_cfg.threshold_off, ...
    'regularization', best_cfg.regularization);
end

function candidates = build_ie_candidate_bank(base_cfg)
q_values = [1.0e-6, 1.0e-5];
window_length_values = [5, 7, 9];
acceleration_decay_values = [0.88, 0.94, 0.98];
initial_acceleration_std_values = [0.06, 0.10];
max_abs_input_values = [0.20, 0.30, 0.45];
threshold_pairs = [
    1.6, 1.0;
    1.8, 1.1;
    2.0, 1.2
];

num_candidates = numel(q_values) * numel(window_length_values) * ...
    numel(acceleration_decay_values) * numel(initial_acceleration_std_values) * ...
    numel(max_abs_input_values) * size(threshold_pairs, 1);
base_cfg.candidate_name = '';
candidates = repmat(base_cfg, num_candidates, 1);
candidate_index = 0;

for q_value = q_values
    for window_length = window_length_values
        for acceleration_decay = acceleration_decay_values
            for initial_acceleration_std = initial_acceleration_std_values
                for max_abs_input = max_abs_input_values
                    for pair_index = 1:size(threshold_pairs, 1)
                        candidate_index = candidate_index + 1;
                        candidate = base_cfg;
                        candidate.q = q_value;
                        candidate.window_length = window_length;
                        candidate.acceleration_decay = acceleration_decay;
                        candidate.initial_acceleration_std = initial_acceleration_std;
                        candidate.max_abs_input = max_abs_input;
                        candidate.threshold_on = threshold_pairs(pair_index, 1);
                        candidate.threshold_off = threshold_pairs(pair_index, 2);
                        candidate.candidate_name = sprintf( ...
                            'q=%.0e, win=%d, decay=%.2f, p0a=%.2f, maxu=%.2f, th=[%.1f %.1f]', ...
                            q_value, window_length, acceleration_decay, initial_acceleration_std, ...
                            max_abs_input, ...
                            candidate.threshold_on, candidate.threshold_off);
                        candidates(candidate_index) = candidate;
                    end
                end
            end
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
