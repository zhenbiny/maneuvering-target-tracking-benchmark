function [best_imm_cfg, tuning] = select_imm_configuration(measurements, truth, cfg)
%SELECT_IMM_CONFIGURATION Choose an IMM setting that best meets the limits.

candidates = build_imm_candidate_bank(cfg);
num_candidates = numel(candidates);
stage1_trials = min(cfg.imm.tuning.stage1_trials, size(measurements.z, 3));
stage1_measurements = slice_measurements(measurements, 1:stage1_trials);
stage1_summaries = repmat(empty_candidate_summary(), num_candidates, 1);

for idx = 1:num_candidates
    trial_cfg = cfg;
    trial_cfg.imm = candidates(idx);
    batch = run_imm_cv_batch(stage1_measurements, trial_cfg);
    evaluated = evaluate_estimates(batch, truth, trial_cfg);
    stage1_summaries(idx) = build_candidate_summary(idx, candidates(idx), evaluated.metrics, cfg, stage1_trials);
end

stage1_order = rank_candidates(stage1_summaries);
top_count = min(cfg.imm.tuning.full_eval_candidates, num_candidates);
top_indices = stage1_order(1:top_count);

full_summaries = repmat(empty_candidate_summary(), top_count, 1);
for rank_index = 1:top_count
    candidate_index = top_indices(rank_index);
    trial_cfg = cfg;
    trial_cfg.imm = candidates(candidate_index);
    batch = run_imm_cv_batch(measurements, trial_cfg);
    evaluated = evaluate_estimates(batch, truth, trial_cfg);
    full_summaries(rank_index) = build_candidate_summary(candidate_index, candidates(candidate_index), evaluated.metrics, cfg, size(measurements.z, 3));
end

full_order = rank_candidates(full_summaries);
selected_summary = full_summaries(full_order(1));
best_imm_cfg = candidates(selected_summary.candidate_index);

tuning = struct();
tuning.stage1_trials = stage1_trials;
tuning.stage1_leaderboard = stage1_summaries(stage1_order(1:min(10, numel(stage1_order))));
tuning.full_leaderboard = full_summaries(full_order);
tuning.selected_candidate = selected_summary;
end

function candidates = build_imm_candidate_bank(cfg)
q_low_values = [1.0e-8, 1.0e-7, 1.0e-6];
q_mid_values = [1.0e-4, 2.5e-4, 5.0e-4];
q_high_values = [2.0e-1, 5.0e-1, 1.0];

transition_bank(:, :, 1) = [
    0.98, 0.015, 0.005;
    0.02, 0.96, 0.02;
    0.005, 0.015, 0.98
];
transition_bank(:, :, 2) = [
    0.99, 0.008, 0.002;
    0.015, 0.97, 0.015;
    0.002, 0.008, 0.99
];

mu0_bank(:, 1) = [0.85; 0.10; 0.05];
mu0_bank(:, 2) = [0.92; 0.06; 0.02];

p0_scale_values = [1.0, 0.25];

base_imm = cfg.imm;
base_imm.candidate_name = '';
candidates = repmat(base_imm, 0, 1);
candidate_index = 0;

for q_low = q_low_values
    for q_mid = q_mid_values
        for q_high = q_high_values
            for transition_index = 1:size(transition_bank, 3)
                for mu_index = 1:size(mu0_bank, 2)
                    for p0_scale = p0_scale_values
                        candidate_index = candidate_index + 1;
                        candidate = base_imm;
                        candidate.q_list = [q_low, q_mid, q_high];
                        candidate.transition_matrix = transition_bank(:, :, transition_index);
                        candidate.mu0 = mu0_bank(:, mu_index);
                        candidate.P0 = p0_scale * base_imm.P0;
                        candidate.candidate_name = sprintf('q=[%.0e %.0e %.1f], T=%d, mu=%d, P=%.2f', ...
                            q_low, q_mid, q_high, transition_index, mu_index, p0_scale);
                        candidates(candidate_index, 1) = candidate;
                    end
                end
            end
        end
    end
end
end

function summary = build_candidate_summary(candidate_index, candidate, metrics, cfg, used_trials)
segment = metrics.segment;
threshold_non = cfg.evaluation.non_maneuver_axis_threshold;
threshold_man = cfg.evaluation.maneuver_axis_threshold;

non_excess = max(segment.axis_non_maneuver - threshold_non, 0);
man_excess = max(segment.axis_maneuver - threshold_man, 0);

summary = empty_candidate_summary();
summary.candidate_index = candidate_index;
summary.candidate_name = candidate.candidate_name;
summary.q_list = candidate.q_list;
summary.transition_matrix = candidate.transition_matrix;
summary.p0_diag = diag(candidate.P0)';
summary.mu0 = candidate.mu0';
summary.used_trials = used_trials;
summary.mean_non_axis = mean(segment.axis_non_maneuver);
summary.max_non_axis = max(segment.axis_non_maneuver);
summary.mean_man_axis = mean(segment.axis_maneuver);
summary.max_man_axis = max(segment.axis_maneuver);
summary.position_non = segment.position_non_maneuver;
summary.position_man = segment.position_maneuver;
summary.non_excess = sum(non_excess);
summary.man_excess = sum(man_excess);
summary.max_non_excess = max(non_excess);
summary.pass_non = all(segment.axis_non_maneuver <= threshold_non);
summary.pass_man = all(segment.axis_maneuver <= threshold_man);
summary.pass_all = summary.pass_non && summary.pass_man;
summary.score_vector = [
    double(~summary.pass_all), ...
    summary.non_excess + summary.man_excess, ...
    summary.max_non_excess, ...
    summary.mean_non_axis, ...
    summary.mean_man_axis, ...
    summary.position_non, ...
    summary.position_man
];
end

function order = rank_candidates(summaries)
score_matrix = zeros(numel(summaries), numel(summaries(1).score_vector));
for idx = 1:numel(summaries)
    score_matrix(idx, :) = summaries(idx).score_vector;
end
[~, order] = sortrows(score_matrix);
end

function summary = empty_candidate_summary()
summary = struct( ...
    'candidate_index', 0, ...
    'candidate_name', '', ...
    'q_list', zeros(1, 3), ...
    'transition_matrix', zeros(3, 3), ...
    'p0_diag', zeros(1, 4), ...
    'mu0', zeros(1, 3), ...
    'used_trials', 0, ...
    'mean_non_axis', inf, ...
    'max_non_axis', inf, ...
    'mean_man_axis', inf, ...
    'max_man_axis', inf, ...
    'position_non', inf, ...
    'position_man', inf, ...
    'non_excess', inf, ...
    'man_excess', inf, ...
    'max_non_excess', inf, ...
    'pass_non', false, ...
    'pass_man', false, ...
    'pass_all', false, ...
    'score_vector', inf(1, 7));
end
