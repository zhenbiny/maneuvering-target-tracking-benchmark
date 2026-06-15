function display_summary(results, cfg)
%DISPLAY_SUMMARY Print the most useful metrics to the command window.

fprintf('\n================ Maneuvering Target Tracking Study ================\n');
fprintf('Sampling interval        : %.2f s\n', cfg.dt);
fprintf('Final simulation time    : %.2f s\n', cfg.t_end);
fprintf('Monte Carlo trials       : %d\n', cfg.num_mc);
fprintf('Measurement covariance R : [%.1f, %.1f; %.1f, %.1f]\n', ...
    cfg.measurement.R(1, 1), cfg.measurement.R(1, 2), ...
    cfg.measurement.R(2, 1), cfg.measurement.R(2, 2));
fprintf('Known initial state      : %s\n', pass_to_text(cfg.use_known_initial_state));
fprintf('Threshold rule           : %s\n', cfg.evaluation.threshold_note);
fprintf('Artifacts directory      : %s\n', cfg.output.directory);
if isfield(results, 'tuning') && isfield(results.tuning, 'selected_candidate')
    selected = results.tuning.selected_candidate;
    fprintf('IMM auto tuning          : YES (candidate %d)\n', selected.candidate_index);
    fprintf('Selected IMM q_list      : [%.2e, %.2e, %.2e]\n', ...
        selected.q_list(1), selected.q_list(2), selected.q_list(3));
end

print_scheme_summary(results.ca, cfg);
print_scheme_summary(results.imm, cfg);
fprintf('===================================================================\n\n');
end

function print_scheme_summary(result, cfg)
segment = result.metrics.segment;

fprintf('\n[%s]\n', result.scheme_name);
fprintf('  Non-maneuver axis RMSE : x = %.2f m, y = %.2f m, limit = %.2f m\n', ...
    segment.axis_non_maneuver(1), ...
    segment.axis_non_maneuver(2), ...
    cfg.evaluation.non_maneuver_axis_threshold);
fprintf('  Maneuver axis RMSE     : x = %.2f m, y = %.2f m, limit = %.2f m\n', ...
    segment.axis_maneuver(1), ...
    segment.axis_maneuver(2), ...
    cfg.evaluation.maneuver_axis_threshold);
fprintf('  Non-maneuver pos RMSE  : %.2f m\n', segment.position_non_maneuver);
fprintf('  Maneuver pos RMSE      : %.2f m\n', segment.position_maneuver);
fprintf('  Axis-threshold pass    : non-maneuver = %s, maneuver = %s\n', ...
    pass_to_text(result.metrics.pass.axis_non_maneuver), ...
    pass_to_text(result.metrics.pass.axis_maneuver));
end

function text_out = pass_to_text(flag)
if flag
    text_out = 'YES';
else
    text_out = 'NO';
end
end
