function animations = export_all_animations(results, cfg)
%EXPORT_ALL_ANIMATIONS Export comparison and per-algorithm animations.

animations = struct();
animations.comparison = struct();
animations.grid = struct();
animations.per_algorithm = struct();

if ~cfg.output.export_animations
    return;
end

output_dir = cfg.output.directory;
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

animations.comparison = export_comparison_animation(results, cfg, output_dir);

if cfg.output.export_grid_animation
    animations.grid = export_grid_animation(results, cfg, output_dir);
end

if cfg.output.export_per_algorithm_animations
    for idx = 1:numel(results.algorithms)
        alg = results.algorithms(idx);
        animations.per_algorithm.(alg.scheme_id) = ...
            export_single_algorithm_animation(results, alg, cfg, output_dir);
    end
end
end

function artifact = export_comparison_animation(results, cfg, output_dir)
time = results.truth.time;
stride = max(1, cfg.output.animation_stride);
artifact = struct();
artifact.gif = fullfile(output_dir, 'comparison_animation.gif');
artifact.video = '';

fig = figure('Name', 'Comparison Animation', 'Color', 'w', 'Visible', 'off', ...
    'Position', [100, 100, 1500, 850]);
trajectory_ax = subplot(1, 2, 1);
error_ax = subplot(1, 2, 2);

limits = trajectory_limits(results.truth.position);
axes(trajectory_ax);
plot(trajectory_ax, results.truth.position(1, :), results.truth.position(2, :), 'Color', [0.9, 0.9, 0.9]);
hold(trajectory_ax, 'on');
measurement_line = plot(trajectory_ax, NaN, NaN, '.', 'Color', [0.82, 0.82, 0.82], 'MarkerSize', 8);
truth_line = plot(trajectory_ax, NaN, NaN, 'k-', 'LineWidth', 1.8);
truth_marker = plot(trajectory_ax, NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
algorithm_lines = gobjects(numel(results.algorithms), 1);
algorithm_markers = gobjects(numel(results.algorithms), 1);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    algorithm_lines(idx) = plot(trajectory_ax, NaN, NaN, 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.4);
    algorithm_markers(idx) = plot(trajectory_ax, NaN, NaN, 'o', 'Color', alg.style.color, ...
        'MarkerFaceColor', alg.style.color, 'MarkerSize', 6);
end
grid(trajectory_ax, 'on');
axis(trajectory_ax, 'equal');
xlim(trajectory_ax, limits.x);
ylim(trajectory_ax, limits.y);
xlabel(trajectory_ax, 'x / m');
ylabel(trajectory_ax, 'y / m');
title(trajectory_ax, 'Trajectory Comparison');
legend(trajectory_ax, [truth_line; measurement_line; algorithm_lines], ...
    [{'Truth'; 'Measurement'}; get_scheme_names(results.algorithms)], 'Location', 'bestoutside');

axes(error_ax);
error_lines = gobjects(numel(results.algorithms), 1);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    error_lines(idx) = plot(error_ax, NaN, NaN, 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.4);
    hold(error_ax, 'on');
end
grid(error_ax, 'on');
xlim(error_ax, [time(1), time(end)]);
ylabel(error_ax, 'Position error / m');
xlabel(error_ax, 'Time / s');
title(error_ax, 'First-Run Position Error');
legend(error_ax, get_scheme_names(results.algorithms), 'Location', 'best');

[video_writer, artifact.video, video_enabled] = open_video_writer(output_dir, 'comparison_animation', cfg.output.animation_delay);

for k = 1:stride:numel(time)
    set(measurement_line, 'XData', results.measurements.first_run(1, 1:k), ...
        'YData', results.measurements.first_run(2, 1:k));
    set(truth_line, 'XData', results.truth.position(1, 1:k), ...
        'YData', results.truth.position(2, 1:k));
    set(truth_marker, 'XData', results.truth.position(1, k), ...
        'YData', results.truth.position(2, k));

    for idx = 1:numel(results.algorithms)
        alg = results.algorithms(idx);
        set(algorithm_lines(idx), 'XData', alg.position_estimates(1, 1:k, 1), ...
            'YData', alg.position_estimates(2, 1:k, 1));
        set(algorithm_markers(idx), 'XData', alg.position_estimates(1, k, 1), ...
            'YData', alg.position_estimates(2, k, 1));

        error_norm = vecnorm(alg.metrics.first_run_position_error(:, 1:k), 2, 1);
        set(error_lines(idx), 'XData', time(1:k), 'YData', error_norm);
    end

    title(trajectory_ax, sprintf('Trajectory Comparison (t = %.0f s)', time(k)));
    title(error_ax, sprintf('First-Run Position Error (t = %.0f s)', time(k)));
    drawnow;

    write_animation_frame(fig, artifact.gif, video_writer, video_enabled, cfg.output.animation_delay, k == 1);
end

if video_enabled
    close(video_writer);
end
close(fig);
end

function artifact = export_grid_animation(results, cfg, output_dir)
time = results.truth.time;
stride = max(1, cfg.output.animation_stride);
artifact = struct();
artifact.gif = fullfile(output_dir, 'grid_animation.gif');
artifact.video = '';

num_algorithms = numel(results.algorithms);
num_cols = ceil(sqrt(num_algorithms));
num_rows = ceil(num_algorithms / num_cols);
limits = trajectory_limits(results.truth.position);

fig = figure('Name', 'Grid Animation', 'Color', 'w', 'Visible', 'off', ...
    'Position', [120, 120, 1500, 900]);

axes_handles = gobjects(num_algorithms, 1);
truth_lines = gobjects(num_algorithms, 1);
measurement_lines = gobjects(num_algorithms, 1);
algorithm_lines = gobjects(num_algorithms, 1);
algorithm_markers = gobjects(num_algorithms, 1);

for idx = 1:num_algorithms
    alg = results.algorithms(idx);
    axes_handles(idx) = subplot(num_rows, num_cols, idx);
    truth_lines(idx) = plot(axes_handles(idx), NaN, NaN, 'k-', 'LineWidth', 1.6);
    hold(axes_handles(idx), 'on');
    measurement_lines(idx) = plot(axes_handles(idx), NaN, NaN, '.', ...
        'Color', [0.82, 0.82, 0.82], 'MarkerSize', 7);
    algorithm_lines(idx) = plot(axes_handles(idx), NaN, NaN, 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.4);
    algorithm_markers(idx) = plot(axes_handles(idx), NaN, NaN, 'o', 'Color', alg.style.color, ...
        'MarkerFaceColor', alg.style.color, 'MarkerSize', 6);
    grid(axes_handles(idx), 'on');
    axis(axes_handles(idx), 'equal');
    xlim(axes_handles(idx), limits.x);
    ylim(axes_handles(idx), limits.y);
    xlabel(axes_handles(idx), 'x / m');
    ylabel(axes_handles(idx), 'y / m');
    title(axes_handles(idx), alg.scheme_name);
end

[video_writer, artifact.video, video_enabled] = open_video_writer(output_dir, 'grid_animation', cfg.output.animation_delay);

for k = 1:stride:numel(time)
    for idx = 1:num_algorithms
        alg = results.algorithms(idx);
        set(truth_lines(idx), 'XData', results.truth.position(1, 1:k), ...
            'YData', results.truth.position(2, 1:k));
        set(measurement_lines(idx), 'XData', results.measurements.first_run(1, 1:k), ...
            'YData', results.measurements.first_run(2, 1:k));
        set(algorithm_lines(idx), 'XData', alg.position_estimates(1, 1:k, 1), ...
            'YData', alg.position_estimates(2, 1:k, 1));
        set(algorithm_markers(idx), 'XData', alg.position_estimates(1, k, 1), ...
            'YData', alg.position_estimates(2, k, 1));
        title(axes_handles(idx), sprintf('%s (t = %.0f s)', alg.scheme_name, time(k)));
    end

    drawnow;
    write_animation_frame(fig, artifact.gif, video_writer, video_enabled, cfg.output.animation_delay, k == 1);
end

if video_enabled
    close(video_writer);
end
close(fig);
end

function artifact = export_single_algorithm_animation(results, algorithm_result, cfg, output_dir)
time = results.truth.time;
stride = max(1, cfg.output.animation_stride);
base_name = ['trajectory_' algorithm_result.scheme_id];
artifact = struct();
artifact.gif = fullfile(output_dir, [base_name '.gif']);
artifact.video = '';

limits = trajectory_limits(results.truth.position);
fig = figure('Name', ['Animation ' algorithm_result.scheme_name], 'Color', 'w', 'Visible', 'off', ...
    'Position', [140, 140, 1500, 850]);
trajectory_ax = subplot(1, 2, 1);
diagnostic_ax = subplot(1, 2, 2);

truth_line = plot(trajectory_ax, NaN, NaN, 'k-', 'LineWidth', 1.8);
hold(trajectory_ax, 'on');
measurement_line = plot(trajectory_ax, NaN, NaN, '.', 'Color', [0.82, 0.82, 0.82], 'MarkerSize', 8);
estimate_line = plot(trajectory_ax, NaN, NaN, 'Color', algorithm_result.style.color, ...
    'LineStyle', algorithm_result.style.line_style, 'LineWidth', 1.5);
truth_marker = plot(trajectory_ax, NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
estimate_marker = plot(trajectory_ax, NaN, NaN, 'o', 'Color', algorithm_result.style.color, ...
    'MarkerFaceColor', algorithm_result.style.color, 'MarkerSize', 6);
grid(trajectory_ax, 'on');
axis(trajectory_ax, 'equal');
xlim(trajectory_ax, limits.x);
ylim(trajectory_ax, limits.y);
xlabel(trajectory_ax, 'x / m');
ylabel(trajectory_ax, 'y / m');
legend(trajectory_ax, {'Truth', 'Measurement', algorithm_result.scheme_name}, 'Location', 'best');

[video_writer, artifact.video, video_enabled] = open_video_writer(output_dir, base_name, cfg.output.animation_delay);

for k = 1:stride:numel(time)
    set(truth_line, 'XData', results.truth.position(1, 1:k), 'YData', results.truth.position(2, 1:k));
    set(measurement_line, 'XData', results.measurements.first_run(1, 1:k), 'YData', results.measurements.first_run(2, 1:k));
    set(estimate_line, 'XData', algorithm_result.position_estimates(1, 1:k, 1), 'YData', algorithm_result.position_estimates(2, 1:k, 1));
    set(truth_marker, 'XData', results.truth.position(1, k), 'YData', results.truth.position(2, k));
    set(estimate_marker, 'XData', algorithm_result.position_estimates(1, k, 1), 'YData', algorithm_result.position_estimates(2, k, 1));
    title(trajectory_ax, sprintf('%s Trajectory (t = %.0f s)', algorithm_result.scheme_name, time(k)));

    cla(diagnostic_ax);
    render_algorithm_diagnostic(diagnostic_ax, results, algorithm_result, cfg, k);

    drawnow;
    write_animation_frame(fig, artifact.gif, video_writer, video_enabled, cfg.output.animation_delay, k == 1);
end

if video_enabled
    close(video_writer);
end
close(fig);
end

function render_algorithm_diagnostic(ax, results, algorithm_result, cfg, k)
time = results.truth.time;

if ~isempty(algorithm_result.model_probabilities)
    hold(ax, 'on');
    for model_index = 1:size(algorithm_result.model_probabilities, 1)
        stairs(ax, time(1:k), squeeze(algorithm_result.model_probabilities(model_index, 1:k, 1)), 'LineWidth', 1.3);
    end
    add_boundary_lines(ax, cfg.plot.boundary_times);
    grid(ax, 'on');
    xlabel(ax, 'Time / s');
    ylabel(ax, 'Probability');
    title(ax, sprintf('%s Model Probabilities', algorithm_result.scheme_name));
    legend(ax, cfg.algorithms.imm_cv.model_labels, 'Location', 'best');
    ylim(ax, [0, 1]);
    xlim(ax, [time(1), time(end)]);
elseif ~isempty(algorithm_result.input_estimates)
    plot(ax, time(1:k), squeeze(algorithm_result.input_estimates(1, 1:k, 1)), ...
        'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
    hold(ax, 'on');
    plot(ax, time(1:k), squeeze(algorithm_result.input_estimates(2, 1:k, 1)), ...
        'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
    add_boundary_lines(ax, cfg.plot.boundary_times);
    grid(ax, 'on');
    xlabel(ax, 'Time / s');
    ylabel(ax, 'Estimated input / (m/s^2)');
    title(ax, sprintf('%s Estimated Inputs', algorithm_result.scheme_name));
    legend(ax, {'x-input', 'y-input'}, 'Location', 'best');
    xlim(ax, [time(1), time(end)]);
elseif ~isempty(algorithm_result.mode_index)
    stairs(ax, time(1:k), squeeze(algorithm_result.mode_index(1, 1:k, 1)), ...
        'Color', algorithm_result.style.color, 'LineWidth', 1.4);
    add_boundary_lines(ax, cfg.plot.boundary_times);
    grid(ax, 'on');
    xlabel(ax, 'Time / s');
    ylabel(ax, 'Mode index');
    title(ax, sprintf('%s Active Mode', algorithm_result.scheme_name));
    xlim(ax, [time(1), time(end)]);
elseif ~isempty(algorithm_result.detector_score)
    plot(ax, time(1:k), squeeze(algorithm_result.detector_score(1, 1:k, 1)), ...
        'Color', algorithm_result.style.color, 'LineWidth', 1.4);
    add_boundary_lines(ax, cfg.plot.boundary_times);
    grid(ax, 'on');
    xlabel(ax, 'Time / s');
    ylabel(ax, 'Score');
    title(ax, sprintf('%s Detector Score', algorithm_result.scheme_name));
    xlim(ax, [time(1), time(end)]);
else
    error_norm = vecnorm(algorithm_result.metrics.first_run_position_error(:, 1:k), 2, 1);
    plot(ax, time(1:k), error_norm, 'Color', algorithm_result.style.color, 'LineWidth', 1.4);
    add_boundary_lines(ax, cfg.plot.boundary_times);
    grid(ax, 'on');
    xlabel(ax, 'Time / s');
    ylabel(ax, 'Position error / m');
    title(ax, sprintf('%s Position Error', algorithm_result.scheme_name));
    xlim(ax, [time(1), time(end)]);
end
end

function limits = trajectory_limits(truth_position)
x_margin = 300;
y_margin = 300;
limits = struct();
limits.x = [min(truth_position(1, :)) - x_margin, max(truth_position(1, :)) + x_margin];
limits.y = [min(truth_position(2, :)) - y_margin, max(truth_position(2, :)) + y_margin];
end

function add_boundary_lines(ax, boundaries)
hold(ax, 'on');
current_limits = ylim(ax);
for idx = 1:numel(boundaries)
    plot(ax, [boundaries(idx), boundaries(idx)], current_limits, 'k:');
end
ylim(ax, current_limits);
end

function write_animation_frame(fig, gif_path, video_writer, video_enabled, delay_time, is_first_frame)
frame = getframe(fig);
frame_image = frame2im(frame);
[frame_image, video_frame] = ensure_even_frame_size(frame_image);
[indexed_image, color_map] = rgb2ind(frame_image, 256);

if is_first_frame
    imwrite(indexed_image, color_map, gif_path, 'gif', 'LoopCount', Inf, 'DelayTime', delay_time);
else
    imwrite(indexed_image, color_map, gif_path, 'gif', 'WriteMode', 'append', 'DelayTime', delay_time);
end

if video_enabled
    writeVideo(video_writer, video_frame);
end
end

function [frame_image, video_frame] = ensure_even_frame_size(frame_image)
[height, width, ~] = size(frame_image);
target_height = height + mod(height, 2);
target_width = width + mod(width, 2);

if target_height ~= height || target_width ~= width
    padded_image = zeros(target_height, target_width, size(frame_image, 3), class(frame_image));
    padded_image(1:height, 1:width, :) = frame_image;

    if target_height > height
        padded_image(end, 1:width, :) = frame_image(end, :, :);
    end
    if target_width > width
        padded_image(1:height, end, :) = frame_image(:, end, :);
    end
    if target_height > height && target_width > width
        padded_image(end, end, :) = frame_image(end, end, :);
    end

    frame_image = padded_image;
end

video_frame = im2frame(frame_image);
end

function [video_writer, video_path, enabled] = open_video_writer(output_dir, base_name, delay_time)
video_writer = [];
enabled = false;
video_path = fullfile(output_dir, [base_name '.mp4']);

try
    video_writer = VideoWriter(video_path, 'MPEG-4');
    video_writer.FrameRate = max(1, round(1 / delay_time));
    open(video_writer);
    enabled = true;
catch
    video_path = fullfile(output_dir, [base_name '.avi']);
    try
        video_writer = VideoWriter(video_path, 'Motion JPEG AVI');
        video_writer.FrameRate = max(1, round(1 / delay_time));
        open(video_writer);
        enabled = true;
    catch
        video_writer = [];
        video_path = '';
        enabled = false;
    end
end
end

function names = get_scheme_names(algorithm_results)
names = cell(numel(algorithm_results), 1);
for idx = 1:numel(algorithm_results)
    names{idx} = algorithm_results(idx).scheme_name;
end
end
