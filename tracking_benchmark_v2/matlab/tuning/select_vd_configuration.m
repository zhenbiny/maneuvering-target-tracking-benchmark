function [best_cfg, tuning] = select_vd_configuration(measurements, truth, cfg)
%SELECT_VD_CONFIGURATION Tune the variable-dimension tracker.

base_cfg = cfg.algorithms.vd_kf;
candidates = build_vd_candidate_bank(base_cfg);
num_candidates = numel(candidates);

stage1_trials = min(base_cfg.tuning.stage1_trials, size(measurements.z, 3));
stage1_measurements = slice_measurements(measurements, 1:stage1_trials);
stage1_summaries = repmat(empty_summary(), num_candidates, 1);

for idx = 1:num_candidates
    batch = run_vd_kf_batch(stage1_measurements, truth, candidates(idx), cfg);
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
    batch = run_vd_kf_batch(measurements, truth, candidates(candidate_index), cfg);
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
    'cv_q', best_cfg.cv_q, ...
    'ca_q', best_cfg.ca_q, ...
    'switch_up_threshold', best_cfg.switch_up_threshold, ...
    'switch_down_threshold', best_cfg.switch_down_threshold, ...
    'switch_back_advantage', best_cfg.switch_back_advantage, ...
    'accel_release_threshold', best_cfg.accel_release_threshold, ...
    'exit_hold_steps', best_cfg.exit_hold_steps);
end

function candidates = build_vd_candidate_bank(base_cfg)
cv_q_values = [1.0e-6, 3.0e-6];
ca_q_values = [3.0e-5, 5.0e-5, 8.0e-5];
switch_up_values = [1.0, 1.5, 2.0];
switch_down_values = [0.2, 0.5, 0.8];
switch_back_advantage_values = [0.2, 0.5, 0.8];
accel_release_values = [1.0, 1.3, 1.6];
exit_hold_values = [2, 3];

num_candidates = numel(cv_q_values) * numel(ca_q_values) * numel(switch_up_values) * ...
    numel(switch_down_values) * numel(switch_back_advantage_values) * ...
    numel(accel_release_values) * numel(exit_hold_values);
base_cfg.candidate_name = '';
candidates = repmat(base_cfg, num_candidates, 1);
candidate_index = 0;

for cv_q = cv_q_values
    for ca_q = ca_q_values
        for switch_up = switch_up_values
            for switch_down = switch_down_values
                for switch_back_advantage = switch_back_advantage_values
                    for accel_release = accel_release_values
                        for exit_hold = exit_hold_values
                            candidate_index = candidate_index + 1;
                            candidate = base_cfg;
                            candidate.cv_q = cv_q;
                            candidate.ca_q = ca_q;
                            candidate.switch_up_threshold = switch_up;
                            candidate.switch_down_threshold = switch_down;
                            candidate.switch_back_advantage = switch_back_advantage;
                            candidate.accel_release_threshold = accel_release;
                            candidate.exit_hold_steps = exit_hold;
                            candidate.candidate_name = sprintf( ...
                                'cvq=%.0e, caq=%.0e, up=%.1f, down=%.1f, back=%.1f, arel=%.1f, hold=%d', ...
                                cv_q, ca_q, switch_up, switch_down, ...
                                switch_back_advantage, accel_release, exit_hold);
                            candidates(candidate_index) = candidate;
                        end
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
