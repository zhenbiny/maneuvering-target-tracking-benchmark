function display_benchmark_summary(results, cfg)
%DISPLAY_BENCHMARK_SUMMARY Print the most useful metrics to the command window.

fprintf('\n================ Rebuilt Tracking Benchmark =======================\n');
fprintf('Project                     : %s\n', cfg.project_name);
fprintf('Sampling interval           : %.2f s\n', cfg.scenario.dt);
fprintf('Final simulation time       : %.2f s\n', cfg.scenario.t_end);
fprintf('Monte Carlo trials          : %d\n', cfg.measurement.num_mc);
fprintf('Measurement covariance R    : [%.1f, %.1f; %.1f, %.1f]\n', ...
    cfg.measurement.R(1, 1), cfg.measurement.R(1, 2), ...
    cfg.measurement.R(2, 1), cfg.measurement.R(2, 2));
fprintf('Known initial state         : %s\n', pass_to_text(cfg.experiment.use_known_initial_state));
fprintf('Threshold rule              : %s\n', cfg.evaluation.threshold_note);
fprintf('Artifacts directory         : %s\n', cfg.output.directory);

print_tuning_line(results.tuning, 'Singer-KF', 'singer_kf');
print_tuning_line(results.tuning, 'IE-KF', 'ie_kf');
print_tuning_line(results.tuning, 'VD-KF', 'vd_kf');
if isfield(results.tuning, 'imm_cv') && isfield(results.tuning.imm_cv, 'selected_candidate')
    selected = results.tuning.imm_cv.selected_candidate;
    fprintf('IMM auto tuning             : YES (candidate %d)\n', selected.candidate_index);
    fprintf('Selected IMM q_list         : [%.2e, %.2e, %.2e]\n', ...
        selected.q_list(1), selected.q_list(2), selected.q_list(3));
end

fprintf('\nRanking Overview:\n');
for idx = 1:numel(results.leaderboard.entries)
    entry = results.leaderboard.entries(idx);
    fprintf('  #%d %-10s pass_all=%s total_excess=%.2f overall_pos_rmse=%.2f m\n', ...
        entry.rank, entry.scheme_name, pass_to_text(entry.pass_all), ...
        entry.total_excess, entry.overall_position_rmse);
end

for idx = 1:numel(results.leaderboard.entries)
    entry = results.leaderboard.entries(idx);
    result = results.named.(entry.scheme_id);
    print_scheme_summary(result, cfg, entry.rank);
end

fprintf('===================================================================\n\n');
end

function print_tuning_line(tuning_struct, scheme_name, field_name)
if isfield(tuning_struct, field_name) && isfield(tuning_struct.(field_name), 'selected_candidate')
    selected = tuning_struct.(field_name).selected_candidate;
    fprintf('%-28s: YES (candidate %d, %s)\n', ...
        [scheme_name ' auto tuning'], selected.candidate_index, selected.candidate_name);
else
    return;
end
end

function print_scheme_summary(result, cfg, rank)
segment = result.metrics.segment;

fprintf('\n[#%d %s]\n', rank, result.scheme_name);
fprintf('  Category                  : %s\n', result.scheme_category);
fprintf('  Non-maneuver axis RMSE    : x = %.2f m, y = %.2f m, limit = %.2f m\n', ...
    segment.axis_non_maneuver(1), segment.axis_non_maneuver(2), ...
    cfg.evaluation.non_maneuver_axis_threshold);
fprintf('  Maneuver axis RMSE        : x = %.2f m, y = %.2f m, limit = %.2f m\n', ...
    segment.axis_maneuver(1), segment.axis_maneuver(2), ...
    cfg.evaluation.maneuver_axis_threshold);
fprintf('  Non-maneuver pos RMSE     : %.2f m\n', segment.position_non_maneuver);
fprintf('  Maneuver pos RMSE         : %.2f m\n', segment.position_maneuver);
fprintf('  Overall pos RMSE          : %.2f m\n', result.metrics.overall.position_rmse);
fprintf('  Peak time-wise pos RMSE   : %.2f m\n', result.metrics.overall.peak_position_rmse_time);
fprintf('  Requirement pass          : non-maneuver = %s, maneuver = %s, overall = %s\n', ...
    pass_to_text(result.metrics.pass.axis_non_maneuver), ...
    pass_to_text(result.metrics.pass.axis_maneuver), ...
    pass_to_text(result.metrics.pass.all));
fprintf('  Runtime                   : %.4f s\n', result.runtime_seconds);
end

function text_out = pass_to_text(flag)
if flag
    text_out = 'YES';
else
    text_out = 'NO';
end
end
