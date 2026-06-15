function summary_table = build_results_table(algorithm_results, leaderboard, cfg)
%BUILD_RESULTS_TABLE Build a paper-friendly summary table.

ordered_results = algorithm_results(leaderboard.order);
num_rows = numel(ordered_results);

rank = zeros(num_rows, 1);
scheme_name = cell(num_rows, 1);
non_x_rmse = zeros(num_rows, 1);
non_y_rmse = zeros(num_rows, 1);
man_x_rmse = zeros(num_rows, 1);
man_y_rmse = zeros(num_rows, 1);
non_pos_rmse = zeros(num_rows, 1);
man_pos_rmse = zeros(num_rows, 1);
overall_pos_rmse = zeros(num_rows, 1);
peak_pos_rmse = zeros(num_rows, 1);
pass_non = false(num_rows, 1);
pass_man = false(num_rows, 1);
pass_all = false(num_rows, 1);
runtime_seconds = zeros(num_rows, 1);
non_margin_min = zeros(num_rows, 1);
man_margin_min = zeros(num_rows, 1);

for idx = 1:num_rows
    result = ordered_results(idx);
    segment = result.metrics.segment;
    rank(idx) = idx;
    scheme_name{idx} = result.scheme_name;
    non_x_rmse(idx) = segment.axis_non_maneuver(1);
    non_y_rmse(idx) = segment.axis_non_maneuver(2);
    man_x_rmse(idx) = segment.axis_maneuver(1);
    man_y_rmse(idx) = segment.axis_maneuver(2);
    non_pos_rmse(idx) = segment.position_non_maneuver;
    man_pos_rmse(idx) = segment.position_maneuver;
    overall_pos_rmse(idx) = result.metrics.overall.position_rmse;
    peak_pos_rmse(idx) = result.metrics.overall.peak_position_rmse_time;
    pass_non(idx) = result.metrics.pass.axis_non_maneuver;
    pass_man(idx) = result.metrics.pass.axis_maneuver;
    pass_all(idx) = result.metrics.pass.all;
    runtime_seconds(idx) = result.runtime_seconds;
    non_margin_min(idx) = min(cfg.evaluation.non_maneuver_axis_threshold - segment.axis_non_maneuver);
    man_margin_min(idx) = min(cfg.evaluation.maneuver_axis_threshold - segment.axis_maneuver);
end

summary_table = table( ...
    rank, scheme_name, ...
    non_x_rmse, non_y_rmse, man_x_rmse, man_y_rmse, ...
    non_pos_rmse, man_pos_rmse, overall_pos_rmse, peak_pos_rmse, ...
    pass_non, pass_man, pass_all, runtime_seconds, ...
    non_margin_min, man_margin_min);
end
