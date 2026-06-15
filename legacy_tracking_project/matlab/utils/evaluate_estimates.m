function result = evaluate_estimates(batch_result, truth, cfg)
%EVALUATE_ESTIMATES Compute time-wise and segment-wise RMSE metrics.

result = batch_result;
num_trials = size(batch_result.position_estimates, 3);
truth_position = repmat(truth.position, 1, 1, num_trials);
errors = batch_result.position_estimates - truth_position;

rmse_x_time = sqrt(mean(errors(1, :, :) .^ 2, 3));
rmse_y_time = sqrt(mean(errors(2, :, :) .^ 2, 3));
rmse_position_time = sqrt(mean(sum(errors .^ 2, 1), 3));

rmse_x_time = reshape(rmse_x_time, 1, []);
rmse_y_time = reshape(rmse_y_time, 1, []);
rmse_position_time = reshape(rmse_position_time, 1, []);

masks = truth.segment_masks;

segment = struct();
segment.axis_non_maneuver = [
    segment_axis_rmse(errors, masks.non_maneuver, 1), ...
    segment_axis_rmse(errors, masks.non_maneuver, 2)
];
segment.axis_maneuver = [
    segment_axis_rmse(errors, masks.maneuver, 1), ...
    segment_axis_rmse(errors, masks.maneuver, 2)
];
segment.position_non_maneuver = segment_position_rmse(errors, masks.non_maneuver);
segment.position_maneuver = segment_position_rmse(errors, masks.maneuver);

pass_flags = struct();
pass_flags.axis_non_maneuver = ...
    all(segment.axis_non_maneuver <= cfg.evaluation.non_maneuver_axis_threshold);
pass_flags.axis_maneuver = ...
    all(segment.axis_maneuver <= cfg.evaluation.maneuver_axis_threshold);

result.metrics = struct();
result.metrics.rmse_x_time = rmse_x_time;
result.metrics.rmse_y_time = rmse_y_time;
result.metrics.rmse_position_time = rmse_position_time;
result.metrics.segment = segment;
result.metrics.pass = pass_flags;
result.metrics.threshold_note = cfg.evaluation.threshold_note;
end

function value = segment_axis_rmse(errors, mask, axis_index)
segment_errors = errors(axis_index, mask, :);
value = sqrt(mean(segment_errors(:) .^ 2));
end

function value = segment_position_rmse(errors, mask)
segment_errors = errors(:, mask, :);
position_error_power = sum(segment_errors .^ 2, 1);
value = sqrt(mean(position_error_power(:)));
end
