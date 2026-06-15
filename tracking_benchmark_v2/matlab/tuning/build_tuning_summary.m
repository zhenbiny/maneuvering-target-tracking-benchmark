function summary = build_tuning_summary(candidate_index, candidate_name, metrics, cfg, used_trials)
%BUILD_TUNING_SUMMARY Convert metrics into a sortable candidate summary.

segment = metrics.segment;
threshold_non = cfg.evaluation.non_maneuver_axis_threshold;
threshold_man = cfg.evaluation.maneuver_axis_threshold;

non_excess = max(segment.axis_non_maneuver - threshold_non, 0);
man_excess = max(segment.axis_maneuver - threshold_man, 0);

summary = struct();
summary.candidate_index = candidate_index;
summary.candidate_name = candidate_name;
summary.used_trials = used_trials;
summary.axis_non_maneuver = segment.axis_non_maneuver;
summary.axis_maneuver = segment.axis_maneuver;
summary.position_non_maneuver = segment.position_non_maneuver;
summary.position_maneuver = segment.position_maneuver;
summary.overall_position_rmse = metrics.overall.position_rmse;
summary.non_excess = sum(non_excess);
summary.man_excess = sum(man_excess);
summary.pass_non = all(segment.axis_non_maneuver <= threshold_non);
summary.pass_man = all(segment.axis_maneuver <= threshold_man);
summary.pass_all = summary.pass_non && summary.pass_man;
summary.score_vector = [
    double(~summary.pass_all), ...
    summary.non_excess + summary.man_excess, ...
    max([non_excess, man_excess]), ...
    mean(segment.axis_non_maneuver), ...
    mean(segment.axis_maneuver), ...
    metrics.overall.position_rmse, ...
    metrics.overall.peak_position_rmse_time
];
end
