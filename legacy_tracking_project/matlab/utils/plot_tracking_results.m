function artifacts = plot_tracking_results(results, cfg)
%PLOT_TRACKING_RESULTS Create paper-ready figures and animation exports.

output_dir = cfg.output.directory;
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

artifacts = struct();
artifacts.output_dir = output_dir;
artifacts.figures = {};
artifacts.animation = struct();

artifacts.figures{end + 1} = create_tracking_overview(results, cfg, output_dir);
artifacts.figures{end + 1} = create_rmse_overview(results, cfg, output_dir);
artifacts.figures{end + 1} = create_state_timeseries(results, cfg, output_dir);
artifacts.figures{end + 1} = create_maneuver_zoom(results, cfg, output_dir);
artifacts.figures{end + 1} = create_probability_figure(results, cfg, output_dir);
artifacts.figures{end + 1} = create_performance_summary(results, cfg, output_dir);

write_tuning_report(results, cfg, output_dir);

if isfield(cfg.output, 'export_animation') && cfg.output.export_animation
    artifacts.animation = export_tracking_animation(results, cfg, output_dir);
end
end

function artifact = create_tracking_overview(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('tracking_overview');

fig = figure('Name', 'Tracking Overview', 'Color', 'w', 'Position', [100, 100, 1300, 900]);

subplot(2, 2, 1);
plot(results.truth.position(1, :), results.truth.position(2, :), 'k-', 'LineWidth', 1.8);
hold on;
plot(results.measurements.first_run(1, :), results.measurements.first_run(2, :), ...
    '.', 'Color', [0.80, 0.80, 0.80], 'MarkerSize', 8);
plot(results.ca.position_estimates(1, :, 1), results.ca.position_estimates(2, :, 1), ...
    '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
plot(results.imm.position_estimates(1, :, 1), results.imm.position_estimates(2, :, 1), ...
    '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.5);
grid on;
axis equal;
xlabel('x / m');
ylabel('y / m');
title('Trajectory Comparison');
legend('Truth', 'Measurement', 'CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 2);
plot(time, results.truth.position(1, :), 'k-', 'LineWidth', 1.4);
hold on;
plot(time, squeeze(results.measurements.first_run(1, :)), '.', 'Color', [0.75, 0.75, 0.75], 'MarkerSize', 7);
plot(time, squeeze(results.ca.position_estimates(1, :, 1)), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
plot(time, squeeze(results.imm.position_estimates(1, :, 1)), '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('x / m');
title('x-Position Time Series');
legend('Truth', 'Measurement', 'CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 3);
plot(time, results.truth.position(2, :), 'k-', 'LineWidth', 1.4);
hold on;
plot(time, squeeze(results.measurements.first_run(2, :)), '.', 'Color', [0.75, 0.75, 0.75], 'MarkerSize', 7);
plot(time, squeeze(results.ca.position_estimates(2, :, 1)), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
plot(time, squeeze(results.imm.position_estimates(2, :, 1)), '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('y / m');
title('y-Position Time Series');
legend('Truth', 'Measurement', 'CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 4);
bar_data = [
    mean(results.ca.metrics.segment.axis_non_maneuver), ...
    mean(results.ca.metrics.segment.axis_maneuver);
    mean(results.imm.metrics.segment.axis_non_maneuver), ...
    mean(results.imm.metrics.segment.axis_maneuver)
];
bar(bar_data);
hold on;
yline(cfg.evaluation.non_maneuver_axis_threshold, 'k--', 'Non-maneuver limit', 'LineWidth', 1.0);
yline(cfg.evaluation.maneuver_axis_threshold, 'k:', 'Maneuver limit', 'LineWidth', 1.0);
grid on;
set(gca, 'XTickLabel', {'CA-KF', 'IMM-CV'});
ylabel('Average axis RMSE / m');
title('Segment RMSE Comparison');
legend('Non-maneuver', 'Maneuver', 'Location', 'northwest');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_rmse_overview(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('rmse_overview');

fig = figure('Name', 'RMSE Overview', 'Color', 'w', 'Position', [120, 120, 1300, 900]);

subplot(2, 2, 1);
plot(time, results.ca.metrics.rmse_position_time, '-', ...
    'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
hold on;
plot(time, results.imm.metrics.rmse_position_time, '-', ...
    'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.5);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position RMSE / m');
title('Position RMSE');
legend('CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 2);
plot(time, results.ca.metrics.rmse_x_time, '--', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.1);
hold on;
plot(time, results.ca.metrics.rmse_y_time, '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.1);
plot(time, results.imm.metrics.rmse_x_time, '--', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
plot(time, results.imm.metrics.rmse_y_time, '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
add_boundary_lines(cfg.plot.boundary_times);
yline(cfg.evaluation.non_maneuver_axis_threshold, 'k--', '50 m threshold', 'LineWidth', 1.0);
grid on;
xlabel('Time / s');
ylabel('Axis RMSE / m');
title('Axis RMSE');
legend('CA-KF x', 'CA-KF y', 'IMM-CV x', 'IMM-CV y', 'Location', 'best');

subplot(2, 2, 3);
imm_error_first = results.imm.position_estimates(:, :, 1) - results.truth.position;
ca_error_first = results.ca.position_estimates(:, :, 1) - results.truth.position;
plot(time, vecnorm(ca_error_first, 2, 1), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
hold on;
plot(time, vecnorm(imm_error_first, 2, 1), '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.4);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Single-run position error / m');
title('Single Realization Error');
legend('CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 4);
stairs(time, squeeze(results.imm.model_probabilities(1, :, 1)), 'LineWidth', 1.2);
hold on;
stairs(time, squeeze(results.imm.model_probabilities(2, :, 1)), 'LineWidth', 1.2);
stairs(time, squeeze(results.imm.model_probabilities(3, :, 1)), 'LineWidth', 1.2);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Model probability');
title('IMM Model Probabilities');
legend(cfg.imm.model_labels, 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_state_timeseries(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('state_timeseries');

fig = figure('Name', 'State Time Series', 'Color', 'w', 'Position', [140, 140, 1400, 900]);

subplot(2, 2, 1);
plot(time, results.truth.velocity(1, :), 'k-', 'LineWidth', 1.4);
hold on;
plot(time, squeeze(results.ca.state_estimates(2, :, 1)), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
plot(time, squeeze(results.imm.state_estimates(2, :, 1)), '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('v_x / (m/s)');
title('x-Velocity');
legend('Truth', 'CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 2);
plot(time, results.truth.velocity(2, :), 'k-', 'LineWidth', 1.4);
hold on;
plot(time, squeeze(results.ca.state_estimates(5, :, 1)), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
plot(time, squeeze(results.imm.state_estimates(4, :, 1)), '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('v_y / (m/s)');
title('y-Velocity');
legend('Truth', 'CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 3);
plot(time, results.truth.acceleration(1, :), 'k-', 'LineWidth', 1.4);
hold on;
plot(time, squeeze(results.ca.state_estimates(3, :, 1)), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_x / (m/s^2)');
title('x-Acceleration');
legend('Truth', 'CA-KF estimate', 'Location', 'best');

subplot(2, 2, 4);
plot(time, results.truth.acceleration(2, :), 'k-', 'LineWidth', 1.4);
hold on;
plot(time, squeeze(results.ca.state_estimates(6, :, 1)), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.2);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_y / (m/s^2)');
title('y-Acceleration');
legend('Truth', 'CA-KF estimate', 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_maneuver_zoom(results, cfg, output_dir)
time = results.truth.time;
zoom_mask = (time >= 350) & (time <= 700);
artifact = initialize_artifact('maneuver_zoom');

fig = figure('Name', 'Maneuver Zoom', 'Color', 'w', 'Position', [160, 160, 1350, 900]);

subplot(2, 2, 1);
plot(results.truth.position(1, zoom_mask), results.truth.position(2, zoom_mask), 'k-', 'LineWidth', 1.8);
hold on;
plot(results.ca.position_estimates(1, zoom_mask, 1), results.ca.position_estimates(2, zoom_mask, 1), ...
    '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
plot(results.imm.position_estimates(1, zoom_mask, 1), results.imm.position_estimates(2, zoom_mask, 1), ...
    '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.5);
grid on;
axis equal;
xlabel('x / m');
ylabel('y / m');
title('Trajectory Zoom: 350 s to 700 s');
legend('Truth', 'CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 2);
plot(time(zoom_mask), results.ca.metrics.rmse_position_time(zoom_mask), '-', ...
    'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
hold on;
plot(time(zoom_mask), results.imm.metrics.rmse_position_time(zoom_mask), '-', ...
    'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.5);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position RMSE / m');
title('RMSE Zoom Around Maneuvers');
legend('CA-KF', 'IMM-CV', 'Location', 'best');

subplot(2, 2, 3);
truth_zoom = results.truth.position(:, zoom_mask);
ca_zoom_error = results.ca.position_estimates(:, zoom_mask, 1) - truth_zoom;
imm_zoom_error = results.imm.position_estimates(:, zoom_mask, 1) - truth_zoom;
plot(time(zoom_mask), ca_zoom_error(1, :), '--', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.1);
hold on;
plot(time(zoom_mask), ca_zoom_error(2, :), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.1);
plot(time(zoom_mask), imm_zoom_error(1, :), '--', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
plot(time(zoom_mask), imm_zoom_error(2, :), '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.3);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position error / m');
title('Single-run Axis Errors');
legend('CA-KF x', 'CA-KF y', 'IMM-CV x', 'IMM-CV y', 'Location', 'best');

subplot(2, 2, 4);
stairs(time(zoom_mask), squeeze(results.imm.model_probabilities(1, zoom_mask, 1)), 'LineWidth', 1.2);
hold on;
stairs(time(zoom_mask), squeeze(results.imm.model_probabilities(2, zoom_mask, 1)), 'LineWidth', 1.2);
stairs(time(zoom_mask), squeeze(results.imm.model_probabilities(3, zoom_mask, 1)), 'LineWidth', 1.2);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Model probability');
title('Model Probabilities in Maneuver Windows');
legend(cfg.imm.model_labels, 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_probability_figure(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('imm_probabilities');

fig = figure('Name', 'IMM Probabilities', 'Color', 'w', 'Position', [180, 180, 1250, 800]);

subplot(3, 1, 1);
stairs(time, squeeze(results.imm.model_probabilities(1, :, 1)), 'LineWidth', 1.4);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
ylabel('Probability');
title(cfg.imm.model_labels{1});

subplot(3, 1, 2);
stairs(time, squeeze(results.imm.model_probabilities(2, :, 1)), 'LineWidth', 1.4);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
ylabel('Probability');
title(cfg.imm.model_labels{2});

subplot(3, 1, 3);
stairs(time, squeeze(results.imm.model_probabilities(3, :, 1)), 'LineWidth', 1.4);
add_boundary_lines(cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Probability');
title(cfg.imm.model_labels{3});

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_performance_summary(results, cfg, output_dir)
artifact = initialize_artifact('performance_summary');

fig = figure('Name', 'Performance Summary', 'Color', 'w', 'Position', [200, 200, 1250, 800]);

ca_segment = results.ca.metrics.segment;
imm_segment = results.imm.metrics.segment;
axis_data = [
    ca_segment.axis_non_maneuver(1), ca_segment.axis_non_maneuver(2);
    imm_segment.axis_non_maneuver(1), imm_segment.axis_non_maneuver(2);
    ca_segment.axis_maneuver(1), ca_segment.axis_maneuver(2);
    imm_segment.axis_maneuver(1), imm_segment.axis_maneuver(2)
];

subplot(1, 2, 1);
bar(axis_data);
hold on;
yline(cfg.evaluation.non_maneuver_axis_threshold, 'k--', '50 m limit', 'LineWidth', 1.0);
yline(cfg.evaluation.maneuver_axis_threshold, 'k:', '150 m limit', 'LineWidth', 1.0);
grid on;
set(gca, 'XTickLabel', {'CA non', 'IMM non', 'CA man', 'IMM man'});
ylabel('Axis RMSE / m');
title('Axis RMSE Summary');
legend('x-axis', 'y-axis', 'Location', 'northwest');

subplot(1, 2, 2);
position_data = [
    ca_segment.position_non_maneuver, ca_segment.position_maneuver;
    imm_segment.position_non_maneuver, imm_segment.position_maneuver
];
bar(position_data);
grid on;
set(gca, 'XTickLabel', {'CA-KF', 'IMM-CV'});
ylabel('Position RMSE / m');
title('Position RMSE Summary');
legend('Non-maneuver', 'Maneuver', 'Location', 'northwest');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function animation = export_tracking_animation(results, cfg, output_dir)
time = results.truth.time;
stride = max(1, cfg.output.animation_stride);
gif_path = fullfile(output_dir, 'trajectory_animation.gif');
mp4_path = fullfile(output_dir, 'trajectory_animation.mp4');

fig = figure('Name', 'Trajectory Animation', 'Color', 'w', 'Visible', 'off', ...
    'Position', [220, 220, 1300, 700]);
trajectory_axes = subplot(1, 2, 1);
probability_axes = subplot(1, 2, 2);

truth_line = plot(trajectory_axes, NaN, NaN, 'k-', 'LineWidth', 1.8);
hold(trajectory_axes, 'on');
measurement_line = plot(trajectory_axes, NaN, NaN, '.', 'Color', [0.80, 0.80, 0.80], 'MarkerSize', 10);
ca_line = plot(trajectory_axes, NaN, NaN, '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 1.3);
imm_line = plot(trajectory_axes, NaN, NaN, '-', 'Color', [0.00, 0.45, 0.74], 'LineWidth', 1.5);
truth_marker = plot(trajectory_axes, NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
imm_marker = plot(trajectory_axes, NaN, NaN, 'o', 'Color', [0.00, 0.45, 0.74], ...
    'MarkerFaceColor', [0.00, 0.45, 0.74], 'MarkerSize', 7);

grid(trajectory_axes, 'on');
axis(trajectory_axes, 'equal');
xlabel(trajectory_axes, 'x / m');
ylabel(trajectory_axes, 'y / m');
title(trajectory_axes, 'Trajectory Animation');
legend(trajectory_axes, [truth_line, measurement_line, ca_line, imm_line], ...
    {'Truth', 'Measurement', 'CA-KF', 'IMM-CV'}, 'Location', 'best');

x_margin = 300;
y_margin = 300;
xlim(trajectory_axes, [min(results.truth.position(1, :)) - x_margin, max(results.truth.position(1, :)) + x_margin]);
ylim(trajectory_axes, [min(results.truth.position(2, :)) - y_margin, max(results.truth.position(2, :)) + y_margin]);

axes(probability_axes);
hold(probability_axes, 'on');
grid(probability_axes, 'on');
xlabel(probability_axes, 'Time / s');
ylabel(probability_axes, 'Model probability');
title(probability_axes, 'IMM Model Probabilities');
xlim(probability_axes, [time(1), time(end)]);
ylim(probability_axes, [0, 1]);

video_writer = [];
video_enabled = false;
try
    video_writer = VideoWriter(mp4_path, 'MPEG-4');
    video_writer.FrameRate = max(1, round(1 / cfg.output.animation_delay));
    open(video_writer);
    video_enabled = true;
catch
    video_enabled = false;
end

for k = 1:stride:numel(time)
    set(truth_line, 'XData', results.truth.position(1, 1:k), 'YData', results.truth.position(2, 1:k));
    set(measurement_line, 'XData', results.measurements.first_run(1, 1:k), 'YData', results.measurements.first_run(2, 1:k));
    set(ca_line, 'XData', results.ca.position_estimates(1, 1:k, 1), 'YData', results.ca.position_estimates(2, 1:k, 1));
    set(imm_line, 'XData', results.imm.position_estimates(1, 1:k, 1), 'YData', results.imm.position_estimates(2, 1:k, 1));
    set(truth_marker, 'XData', results.truth.position(1, k), 'YData', results.truth.position(2, k));
    set(imm_marker, 'XData', results.imm.position_estimates(1, k, 1), 'YData', results.imm.position_estimates(2, k, 1));

    cla(probability_axes);
    stairs(probability_axes, time(1:k), squeeze(results.imm.model_probabilities(1, 1:k, 1)), 'LineWidth', 1.2);
    hold(probability_axes, 'on');
    stairs(probability_axes, time(1:k), squeeze(results.imm.model_probabilities(2, 1:k, 1)), 'LineWidth', 1.2);
    stairs(probability_axes, time(1:k), squeeze(results.imm.model_probabilities(3, 1:k, 1)), 'LineWidth', 1.2);
    add_boundary_lines(cfg.plot.boundary_times);
    grid(probability_axes, 'on');
    xlabel(probability_axes, 'Time / s');
    ylabel(probability_axes, 'Model probability');
    title(probability_axes, sprintf('IMM Model Probabilities (t = %.0f s)', time(k)));
    legend(probability_axes, cfg.imm.model_labels, 'Location', 'best');
    xlim(probability_axes, [time(1), time(end)]);
    ylim(probability_axes, [0, 1]);

    title(trajectory_axes, sprintf('Trajectory Animation (t = %.0f s)', time(k)));
    drawnow;

    frame = getframe(fig);
    frame_image = frame2im(frame);
    [indexed_image, color_map] = rgb2ind(frame_image, 256);

    if k == 1
        imwrite(indexed_image, color_map, gif_path, 'gif', ...
            'LoopCount', Inf, 'DelayTime', cfg.output.animation_delay);
    else
        imwrite(indexed_image, color_map, gif_path, 'gif', ...
            'WriteMode', 'append', 'DelayTime', cfg.output.animation_delay);
    end

    if video_enabled
        writeVideo(video_writer, frame);
    end
end

if video_enabled
    close(video_writer);
end

close(fig);

animation = struct();
animation.gif = gif_path;
if video_enabled
    animation.mp4 = mp4_path;
else
    animation.mp4 = '';
end
end

function write_tuning_report(results, cfg, output_dir)
report_path = fullfile(output_dir, 'tuning_report.txt');
fid = fopen(report_path, 'w');
if fid < 0
    return;
end

cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Maneuvering Target Tracking Report\n');
fprintf(fid, '=================================\n\n');
fprintf(fid, 'Sampling interval: %.2f s\n', cfg.dt);
fprintf(fid, 'Final time: %.2f s\n', cfg.t_end);
fprintf(fid, 'Monte Carlo trials: %d\n\n', cfg.num_mc);

fprintf(fid, '[CA-KF]\n');
write_metric_block(fid, results.ca.metrics.segment);
fprintf(fid, '\n[IMM-CV]\n');
write_metric_block(fid, results.imm.metrics.segment);

if isfield(results, 'tuning') && isfield(results.tuning, 'selected_candidate')
    candidate = results.tuning.selected_candidate;
    fprintf(fid, '\n[IMM Auto Tuning]\n');
    fprintf(fid, 'Selected candidate index: %d\n', candidate.candidate_index);
    fprintf(fid, 'Candidate label: %s\n', candidate.candidate_name);
    fprintf(fid, 'q_list: [%.4e, %.4e, %.4e]\n', ...
        candidate.q_list(1), candidate.q_list(2), candidate.q_list(3));
    fprintf(fid, 'mu0: [%.4f, %.4f, %.4f]\n', ...
        candidate.mu0(1), candidate.mu0(2), candidate.mu0(3));
    fprintf(fid, 'P0 diagonal: [%.4f, %.4f, %.4f, %.4f]\n', ...
        candidate.p0_diag(1), candidate.p0_diag(2), candidate.p0_diag(3), candidate.p0_diag(4));
    fprintf(fid, 'Transition matrix:\n');
    for row = 1:size(candidate.transition_matrix, 1)
        fprintf(fid, '  [%.4f, %.4f, %.4f]\n', candidate.transition_matrix(row, :));
    end
end
end

function write_metric_block(fid, segment)
fprintf(fid, '  Non-maneuver axis RMSE: x = %.4f m, y = %.4f m\n', ...
    segment.axis_non_maneuver(1), segment.axis_non_maneuver(2));
fprintf(fid, '  Maneuver axis RMSE: x = %.4f m, y = %.4f m\n', ...
    segment.axis_maneuver(1), segment.axis_maneuver(2));
fprintf(fid, '  Non-maneuver position RMSE: %.4f m\n', segment.position_non_maneuver);
fprintf(fid, '  Maneuver position RMSE: %.4f m\n', segment.position_maneuver);
end

function artifact = initialize_artifact(base_name)
artifact = struct();
artifact.name = base_name;
artifact.png = '';
artifact.fig = '';
end

function artifact = save_figure_artifact(fig, artifact, output_dir, cfg)
if cfg.output.save_png
    artifact.png = fullfile(output_dir, [artifact.name, '.png']);
    exportgraphics(fig, artifact.png, 'Resolution', 200);
end
if cfg.output.save_fig
    artifact.fig = fullfile(output_dir, [artifact.name, '.fig']);
    savefig(fig, artifact.fig);
end
end

function add_boundary_lines(boundaries)
hold_state = ishold;
hold on;
current_limits = ylim;
for idx = 1:numel(boundaries)
    plot([boundaries(idx), boundaries(idx)], current_limits, 'k:');
end
ylim(current_limits);
if ~hold_state
    hold off;
end
end
