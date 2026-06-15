function leaderboard = build_leaderboard(algorithm_results, cfg)
%BUILD_LEADERBOARD Rank algorithms by requirement satisfaction and accuracy.

entries = repmat(empty_entry(), numel(algorithm_results), 1);

for idx = 1:numel(algorithm_results)
    result = algorithm_results(idx);
    segment = result.metrics.segment;

    non_excess = max(segment.axis_non_maneuver - cfg.evaluation.non_maneuver_axis_threshold, 0);
    man_excess = max(segment.axis_maneuver - cfg.evaluation.maneuver_axis_threshold, 0);
    total_excess = sum(non_excess) + sum(man_excess);

    entries(idx).scheme_id = result.scheme_id;
    entries(idx).scheme_name = result.scheme_name;
    entries(idx).pass_non_maneuver = result.metrics.pass.axis_non_maneuver;
    entries(idx).pass_maneuver = result.metrics.pass.axis_maneuver;
    entries(idx).pass_all = result.metrics.pass.all;
    entries(idx).mean_non_axis = mean(segment.axis_non_maneuver);
    entries(idx).mean_maneuver_axis = mean(segment.axis_maneuver);
    entries(idx).position_non_maneuver = segment.position_non_maneuver;
    entries(idx).position_maneuver = segment.position_maneuver;
    entries(idx).overall_position_rmse = result.metrics.overall.position_rmse;
    entries(idx).peak_position_rmse = result.metrics.overall.peak_position_rmse_time;
    entries(idx).runtime_seconds = result.runtime_seconds;
    entries(idx).total_excess = total_excess;
    entries(idx).score_vector = [
        double(~result.metrics.pass.all), ...
        total_excess, ...
        max([non_excess, man_excess]), ...
        mean(segment.axis_non_maneuver), ...
        mean(segment.axis_maneuver), ...
        result.metrics.overall.position_rmse, ...
        result.runtime_seconds
    ];
end

score_matrix = zeros(numel(entries), numel(entries(1).score_vector));
for idx = 1:numel(entries)
    score_matrix(idx, :) = entries(idx).score_vector;
end
[~, order] = sortrows(score_matrix);
entries = entries(order);

for idx = 1:numel(entries)
    entries(idx).rank = idx;
end

leaderboard = struct();
leaderboard.order = order;
leaderboard.entries = entries;
leaderboard.table = build_table(entries);
end

function entry = empty_entry()
entry = struct( ...
    'rank', 0, ...
    'scheme_id', '', ...
    'scheme_name', '', ...
    'pass_non_maneuver', false, ...
    'pass_maneuver', false, ...
    'pass_all', false, ...
    'mean_non_axis', inf, ...
    'mean_maneuver_axis', inf, ...
    'position_non_maneuver', inf, ...
    'position_maneuver', inf, ...
    'overall_position_rmse', inf, ...
    'peak_position_rmse', inf, ...
    'runtime_seconds', inf, ...
    'total_excess', inf, ...
    'score_vector', inf(1, 7));
end

function tbl = build_table(entries)
num_rows = numel(entries);
rank = zeros(num_rows, 1);
scheme_name = cell(num_rows, 1);
pass_all = false(num_rows, 1);
pass_non_maneuver = false(num_rows, 1);
pass_maneuver = false(num_rows, 1);
mean_non_axis = zeros(num_rows, 1);
mean_maneuver_axis = zeros(num_rows, 1);
position_non_maneuver = zeros(num_rows, 1);
position_maneuver = zeros(num_rows, 1);
overall_position_rmse = zeros(num_rows, 1);
peak_position_rmse = zeros(num_rows, 1);
runtime_seconds = zeros(num_rows, 1);
total_excess = zeros(num_rows, 1);

for idx = 1:num_rows
    rank(idx) = entries(idx).rank;
    scheme_name{idx} = entries(idx).scheme_name;
    pass_all(idx) = entries(idx).pass_all;
    pass_non_maneuver(idx) = entries(idx).pass_non_maneuver;
    pass_maneuver(idx) = entries(idx).pass_maneuver;
    mean_non_axis(idx) = entries(idx).mean_non_axis;
    mean_maneuver_axis(idx) = entries(idx).mean_maneuver_axis;
    position_non_maneuver(idx) = entries(idx).position_non_maneuver;
    position_maneuver(idx) = entries(idx).position_maneuver;
    overall_position_rmse(idx) = entries(idx).overall_position_rmse;
    peak_position_rmse(idx) = entries(idx).peak_position_rmse;
    runtime_seconds(idx) = entries(idx).runtime_seconds;
    total_excess(idx) = entries(idx).total_excess;
end

tbl = table( ...
    rank, scheme_name, pass_all, pass_non_maneuver, pass_maneuver, ...
    mean_non_axis, mean_maneuver_axis, position_non_maneuver, position_maneuver, ...
    overall_position_rmse, peak_position_rmse, runtime_seconds, total_excess);
end
