function artifacts = plot_benchmark_results(results, cfg)
%PLOT_BENCHMARK_RESULTS Create paper-ready figures and tables.

output_dir = cfg.output.directory;
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

artifacts = struct();
artifacts.output_dir = output_dir;
artifacts.figures = repmat(struct('name', '', 'png', '', 'fig', ''), 0, 1);
artifacts.tables = struct();

artifacts.figures = append_figure_artifact(artifacts.figures, create_trajectory_overview(results, cfg, output_dir));
artifacts.figures = append_figure_artifact(artifacts.figures, create_rmse_overview(results, cfg, output_dir));
artifacts.figures = append_figure_artifact(artifacts.figures, create_segment_scoreboard(results, cfg, output_dir));
artifacts.figures = append_figure_artifact(artifacts.figures, create_maneuver_zoom(results, cfg, output_dir));
artifacts.figures = append_figure_artifact(artifacts.figures, create_state_comparison(results, cfg, output_dir));
artifacts.figures = append_figure_artifact(artifacts.figures, create_leaderboard_summary(results, cfg, output_dir));

[imm_result, imm_index] = find_algorithm_result(results, 'imm_cv');
if ~isempty(imm_index)
    artifacts.figures = append_figure_artifact(artifacts.figures, ...
        create_imm_diagnostics(results, imm_result, cfg, output_dir));
end

[ie_result, ie_index] = find_algorithm_result(results, 'ie_kf');
if ~isempty(ie_index)
    artifacts.figures = append_figure_artifact(artifacts.figures, ...
        create_ie_diagnostics(results, ie_result, cfg, output_dir));
end

[vd_result, vd_index] = find_algorithm_result(results, 'vd_kf');
if ~isempty(vd_index)
    artifacts.figures = append_figure_artifact(artifacts.figures, ...
        create_vd_diagnostics(results, vd_result, cfg, output_dir));
end

artifacts.tables = write_summary_tables(results, cfg, output_dir);
end

function artifact = create_trajectory_overview(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('trajectory_overview');

fig = figure('Name', 'Trajectory Overview', 'Color', 'w', 'Position', [80, 80, 1450, 920]);

subplot(2, 2, 1);
plot(results.truth.position(1, :), results.truth.position(2, :), 'k-', 'LineWidth', 1.8);
hold on;
plot(results.measurements.first_run(1, :), results.measurements.first_run(2, :), '.', ...
    'Color', [0.82, 0.82, 0.82], 'MarkerSize', 8);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(alg.position_estimates(1, :, 1), alg.position_estimates(2, :, 1), ...
        'Color', alg.style.color, 'LineStyle', alg.style.line_style, 'LineWidth', 1.4);
end
grid on;
axis equal;
xlabel('x / m');
ylabel('y / m');
title('Trajectory Comparison');
legend_entries = [{'Truth', 'Measurement'}, get_scheme_names(results.algorithms)'];
legend(legend_entries, 'Location', 'bestoutside');

subplot(2, 2, 2);
plot(time, results.truth.position(1, :), 'k-', 'LineWidth', 1.6);
hold on;
plot(time, results.measurements.first_run(1, :), '.', 'Color', [0.82, 0.82, 0.82], 'MarkerSize', 8);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, alg.position_estimates(1, :, 1), 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('x / m');
title('x-Position Time Series');

subplot(2, 2, 3);
plot(time, results.truth.position(2, :), 'k-', 'LineWidth', 1.6);
hold on;
plot(time, results.measurements.first_run(2, :), '.', 'Color', [0.82, 0.82, 0.82], 'MarkerSize', 8);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, alg.position_estimates(2, :, 1), 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('y / m');
title('y-Position Time Series');

subplot(2, 2, 4);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    error_norm = vecnorm(alg.metrics.first_run_position_error, 2, 1);
    plot(time, error_norm, 'Color', alg.style.color, 'LineStyle', alg.style.line_style, 'LineWidth', 1.3);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position error / m');
title('Single-Run Position Error Norm');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_rmse_overview(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('rmse_overview');

fig = figure('Name', 'RMSE Overview', 'Color', 'w', 'Position', [100, 100, 1450, 920]);

subplot(2, 2, 1);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, alg.metrics.rmse_position_time, 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.5);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position RMSE / m');
title('Time-wise Position RMSE');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

subplot(2, 2, 2);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, alg.metrics.rmse_x_time, 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.3);
    hold on;
end
yline(cfg.evaluation.non_maneuver_axis_threshold, 'k--', '50 m');
yline(cfg.evaluation.maneuver_axis_threshold, 'k:', '150 m');
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('x-axis RMSE / m');
title('Time-wise x-Axis RMSE');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

subplot(2, 2, 3);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, alg.metrics.rmse_y_time, 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.3);
    hold on;
end
yline(cfg.evaluation.non_maneuver_axis_threshold, 'k--', '50 m');
yline(cfg.evaluation.maneuver_axis_threshold, 'k:', '150 m');
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('y-axis RMSE / m');
title('Time-wise y-Axis RMSE');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

subplot(2, 2, 4);
overall_rmse = zeros(numel(results.algorithms), 1);
peak_rmse = zeros(numel(results.algorithms), 1);
for idx = 1:numel(results.algorithms)
    overall_rmse(idx) = results.algorithms(idx).metrics.overall.position_rmse;
    peak_rmse(idx) = results.algorithms(idx).metrics.overall.peak_position_rmse_time;
end
bar([overall_rmse, peak_rmse]);
grid on;
set(gca, 'XTick', 1:numel(results.algorithms), 'XTickLabel', get_scheme_names(results.algorithms));
xtickangle(25);
ylabel('RMSE / m');
title('Overall and Peak Position RMSE');
legend({'Overall', 'Peak'}, 'Location', 'northwest');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_segment_scoreboard(results, cfg, output_dir)
artifact = initialize_artifact('segment_scoreboard');
scheme_names = get_scheme_names(results.algorithms);
num_algorithms = numel(results.algorithms);

non_axis = zeros(num_algorithms, 2);
man_axis = zeros(num_algorithms, 2);
pos_data = zeros(num_algorithms, 2);
runtime_seconds = zeros(num_algorithms, 1);
non_margin_min = zeros(num_algorithms, 1);
man_margin_min = zeros(num_algorithms, 1);
for idx = 1:num_algorithms
    segment = results.algorithms(idx).metrics.segment;
    non_axis(idx, :) = segment.axis_non_maneuver;
    man_axis(idx, :) = segment.axis_maneuver;
    pos_data(idx, :) = [segment.position_non_maneuver, segment.position_maneuver];
    runtime_seconds(idx) = results.algorithms(idx).runtime_seconds;
    non_margin_min(idx) = min(cfg.evaluation.non_maneuver_axis_threshold - segment.axis_non_maneuver);
    man_margin_min(idx) = min(cfg.evaluation.maneuver_axis_threshold - segment.axis_maneuver);
end

fig = figure('Name', 'Segment Scoreboard', 'Color', 'w', 'Position', [120, 120, 1450, 920]);

subplot(2, 2, 1);
bar(non_axis);
hold on;
yline(cfg.evaluation.non_maneuver_axis_threshold, 'k--', '50 m limit');
grid on;
set(gca, 'XTick', 1:num_algorithms, 'XTickLabel', scheme_names);
xtickangle(25);
ylabel('Axis RMSE / m');
title('Non-maneuver Axis RMSE');
legend({'x', 'y'}, 'Location', 'northwest');

subplot(2, 2, 2);
bar(man_axis);
hold on;
yline(cfg.evaluation.maneuver_axis_threshold, 'k--', '150 m limit');
grid on;
set(gca, 'XTick', 1:num_algorithms, 'XTickLabel', scheme_names);
xtickangle(25);
ylabel('Axis RMSE / m');
title('Maneuver Axis RMSE');
legend({'x', 'y'}, 'Location', 'northwest');

subplot(2, 2, 3);
bar(pos_data);
grid on;
set(gca, 'XTick', 1:num_algorithms, 'XTickLabel', scheme_names);
xtickangle(25);
ylabel('Position RMSE / m');
title('Segment Position RMSE');
legend({'Non-maneuver', 'Maneuver'}, 'Location', 'northwest');

subplot(2, 2, 4);
yyaxis left;
bar(runtime_seconds, 'FaceColor', [0.50, 0.50, 0.50]);
ylabel('Runtime / s');
yyaxis right;
plot(1:num_algorithms, non_margin_min, 'o-', 'LineWidth', 1.2, 'Color', [0.85, 0.33, 0.10]);
hold on;
plot(1:num_algorithms, man_margin_min, 's-', 'LineWidth', 1.2, 'Color', [0.00, 0.45, 0.74]);
yline(0, 'k--', 'Zero margin');
grid on;
set(gca, 'XTick', 1:num_algorithms, 'XTickLabel', scheme_names);
xtickangle(25);
ylabel('Threshold margin / m');
title('Runtime and Tightest Threshold Margin');
legend({'Runtime', 'Non-maneuver margin', 'Maneuver margin'}, 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_maneuver_zoom(results, cfg, output_dir)
time = results.truth.time;
zoom_mask = (time >= 350) & (time <= 700);
artifact = initialize_artifact('maneuver_zoom');

fig = figure('Name', 'Maneuver Zoom', 'Color', 'w', 'Position', [140, 140, 1450, 920]);

subplot(2, 2, 1);
plot(results.truth.position(1, zoom_mask), results.truth.position(2, zoom_mask), 'k-', 'LineWidth', 1.8);
hold on;
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(alg.position_estimates(1, zoom_mask, 1), alg.position_estimates(2, zoom_mask, 1), ...
        'Color', alg.style.color, 'LineStyle', alg.style.line_style, 'LineWidth', 1.4);
end
grid on;
axis equal;
xlabel('x / m');
ylabel('y / m');
title('Trajectory Zoom (350 s to 700 s)');
legend([{'Truth'}, get_scheme_names(results.algorithms)'], 'Location', 'bestoutside');

subplot(2, 2, 2);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time(zoom_mask), alg.metrics.rmse_position_time(zoom_mask), ...
        'Color', alg.style.color, 'LineStyle', alg.style.line_style, 'LineWidth', 1.4);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position RMSE / m');
title('Position RMSE Around Maneuvers');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

subplot(2, 2, 3);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time(zoom_mask), alg.metrics.first_run_position_error(1, zoom_mask), ...
        'Color', alg.style.color, 'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('x-error / m');
title('Single-Run x-Error Around Maneuvers');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

subplot(2, 2, 4);
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time(zoom_mask), alg.metrics.first_run_position_error(2, zoom_mask), ...
        'Color', alg.style.color, 'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('y-error / m');
title('Single-Run y-Error Around Maneuvers');
legend(get_scheme_names(results.algorithms), 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_state_comparison(results, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('state_comparison');

fig = figure('Name', 'State Comparison', 'Color', 'w', 'Position', [160, 160, 1450, 920]);

subplot(2, 2, 1);
plot(time, results.truth.velocity(1, :), 'k-', 'LineWidth', 1.6);
hold on;
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, squeeze(alg.state_estimates(2, :, 1)), 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('v_x / (m/s)');
title('x-Velocity');
legend([{'Truth'}, get_scheme_names(results.algorithms)'], 'Location', 'best');

subplot(2, 2, 2);
plot(time, results.truth.velocity(2, :), 'k-', 'LineWidth', 1.6);
hold on;
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    plot(time, squeeze(alg.state_estimates(5, :, 1)), 'Color', alg.style.color, ...
        'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('v_y / (m/s)');
title('y-Velocity');
legend([{'Truth'}, get_scheme_names(results.algorithms)'], 'Location', 'best');

subplot(2, 2, 3);
plot(time, results.truth.acceleration(1, :), 'k-', 'LineWidth', 1.6);
hold on;
accel_names = {'Truth'};
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    if has_nonzero_acceleration_content(alg)
        plot(time, squeeze(alg.state_estimates(3, :, 1)), 'Color', alg.style.color, ...
            'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
        accel_names{end + 1} = alg.scheme_name; %#ok<AGROW>
    end
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_x / (m/s^2)');
title('x-Acceleration');
legend(accel_names, 'Location', 'best');

subplot(2, 2, 4);
plot(time, results.truth.acceleration(2, :), 'k-', 'LineWidth', 1.6);
hold on;
accel_names = {'Truth'};
for idx = 1:numel(results.algorithms)
    alg = results.algorithms(idx);
    if has_nonzero_acceleration_content(alg)
        plot(time, squeeze(alg.state_estimates(6, :, 1)), 'Color', alg.style.color, ...
            'LineStyle', alg.style.line_style, 'LineWidth', 1.2);
        accel_names{end + 1} = alg.scheme_name; %#ok<AGROW>
    end
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_y / (m/s^2)');
title('y-Acceleration');
legend(accel_names, 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_leaderboard_summary(results, cfg, output_dir)
artifact = initialize_artifact('leaderboard_summary');
tbl = results.table;

fig = figure('Name', 'Leaderboard Summary', 'Color', 'w', 'Position', [180, 180, 1450, 920]);

subplot(1, 2, 1);
bar([tbl.non_margin_min, tbl.man_margin_min]);
hold on;
yline(0, 'k--', 'Pass boundary');
grid on;
set(gca, 'XTick', 1:height(tbl), 'XTickLabel', tbl.scheme_name);
xtickangle(25);
ylabel('Smallest axis margin / m');
title('Pass Margin Summary');
legend({'Non-maneuver', 'Maneuver'}, 'Location', 'best');

subplot(1, 2, 2);
axis off;
text(0.00, 1.00, sprintf('Thresholds: non-maneuver %.1f m, maneuver %.1f m', ...
    cfg.evaluation.non_maneuver_axis_threshold, cfg.evaluation.maneuver_axis_threshold), ...
    'FontWeight', 'bold', 'FontSize', 12, 'VerticalAlignment', 'top');
text_y = 0.92;
for idx = 1:height(tbl)
    summary_line = sprintf( ...
        '#%d %s | pass=%s | non=(%.2f, %.2f) m | man=(%.2f, %.2f) m | overall=%.2f m | runtime=%.3f s', ...
        tbl.rank(idx), tbl.scheme_name{idx}, pass_to_text(tbl.pass_all(idx)), ...
        tbl.non_x_rmse(idx), tbl.non_y_rmse(idx), ...
        tbl.man_x_rmse(idx), tbl.man_y_rmse(idx), ...
        tbl.overall_pos_rmse(idx), tbl.runtime_seconds(idx));
    text(0.00, text_y, summary_line, 'FontName', 'Consolas', 'FontSize', 10, 'VerticalAlignment', 'top');
    text_y = text_y - 0.10;
end
title('Ranking Text Summary');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_imm_diagnostics(results, imm_result, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('imm_diagnostics');
zoom_mask = (time >= 350) & (time <= 700);

fig = figure('Name', 'IMM Diagnostics', 'Color', 'w', 'Position', [200, 200, 1450, 920]);

subplot(2, 2, 1);
for model_index = 1:size(imm_result.model_probabilities, 1)
    stairs(time, squeeze(imm_result.model_probabilities(model_index, :, 1)), 'LineWidth', 1.3);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Model probability');
title('IMM Model Probabilities');
legend(cfg.algorithms.imm_cv.model_labels, 'Location', 'best');

subplot(2, 2, 2);
for model_index = 1:size(imm_result.model_probabilities, 1)
    stairs(time(zoom_mask), squeeze(imm_result.model_probabilities(model_index, zoom_mask, 1)), 'LineWidth', 1.3);
    hold on;
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Model probability');
title('IMM Probabilities Around Maneuvers');
legend(cfg.algorithms.imm_cv.model_labels, 'Location', 'best');

subplot(2, 2, 3);
plot(time, imm_result.metrics.rmse_position_time, 'Color', imm_result.style.color, 'LineWidth', 1.5);
hold on;
[ca_result, ca_index] = find_algorithm_result(results, 'ca_kf');
if ~isempty(ca_index)
    plot(time, ca_result.metrics.rmse_position_time, '--', 'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.2);
    legend_entries = {'IMM-CV', 'CA-KF'};
else
    legend_entries = {'IMM-CV'};
end
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Position RMSE / m');
title('IMM vs CA Position RMSE');
legend(legend_entries, 'Location', 'best');

subplot(2, 2, 4);
plot(results.truth.position(1, zoom_mask), results.truth.position(2, zoom_mask), 'k-', 'LineWidth', 1.7);
hold on;
plot(imm_result.position_estimates(1, zoom_mask, 1), imm_result.position_estimates(2, zoom_mask, 1), ...
    'Color', imm_result.style.color, 'LineWidth', 1.5);
grid on;
axis equal;
xlabel('x / m');
ylabel('y / m');
title('IMM Trajectory Zoom');
legend({'Truth', 'IMM-CV'}, 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_ie_diagnostics(results, ie_result, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('ie_diagnostics');

fig = figure('Name', 'IE Diagnostics', 'Color', 'w', 'Position', [220, 220, 1450, 920]);

subplot(2, 2, 1);
plot(time, results.truth.acceleration(1, :), 'k-', 'LineWidth', 1.6);
hold on;
plot(time, squeeze(ie_result.input_estimates(1, :, 1)), 'Color', ie_result.style.color, 'LineWidth', 1.4);
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_x / (m/s^2)');
title('Estimated x-Acceleration Input');
legend({'Truth', 'IE-KF'}, 'Location', 'best');

subplot(2, 2, 2);
plot(time, results.truth.acceleration(2, :), 'k-', 'LineWidth', 1.6);
hold on;
plot(time, squeeze(ie_result.input_estimates(2, :, 1)), 'Color', ie_result.style.color, 'LineWidth', 1.4);
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_y / (m/s^2)');
title('Estimated y-Acceleration Input');
legend({'Truth', 'IE-KF'}, 'Location', 'best');

subplot(2, 2, 3);
plot(time, squeeze(ie_result.detector_score(1, :, 1)), 'Color', ie_result.style.color, 'LineWidth', 1.4);
hold on;
yline(cfg.algorithms.ie_kf.threshold_on, 'k--', 'On threshold');
yline(cfg.algorithms.ie_kf.threshold_off, 'k:', 'Off threshold');
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Acceleration significance score');
title('IE Detector Score');
legend({'Detector score', 'On threshold', 'Off threshold'}, 'Location', 'best');

subplot(2, 2, 4);
stairs(time, squeeze(ie_result.mode_index(1, :, 1)), 'Color', ie_result.style.color, 'LineWidth', 1.4);
ylim([0.8, 2.2]);
yticks([1, 2]);
yticklabels({'steady', 'maneuver'});
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Mode');
title('IE Maneuver Decision');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function artifact = create_vd_diagnostics(results, vd_result, cfg, output_dir)
time = results.truth.time;
artifact = initialize_artifact('vd_diagnostics');

fig = figure('Name', 'VD Diagnostics', 'Color', 'w', 'Position', [240, 240, 1450, 920]);

subplot(2, 2, 1);
stairs(time, squeeze(vd_result.mode_index(1, :, 1)), 'Color', vd_result.style.color, 'LineWidth', 1.4);
ylim([0.8, 2.2]);
yticks([1, 2]);
yticklabels({'CV', 'CA'});
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Active dimension');
title('VD Mode Switching');

subplot(2, 2, 2);
plot(time, squeeze(vd_result.detector_score(1, :, 1)), 'Color', vd_result.style.color, 'LineWidth', 1.4);
hold on;
yline(cfg.algorithms.vd_kf.switch_up_threshold, 'k--', 'Switch-up threshold');
yline(cfg.algorithms.vd_kf.switch_down_threshold, 'k:', 'Switch-down threshold');
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('Detector score');
title('VD Switching Score');
legend({'Score', 'Up threshold', 'Down threshold'}, 'Location', 'best');

subplot(2, 2, 3);
plot(time, results.truth.acceleration(1, :), 'k-', 'LineWidth', 1.6);
hold on;
plot(time, squeeze(vd_result.state_estimates(3, :, 1)), 'Color', vd_result.style.color, 'LineWidth', 1.3);
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_x / (m/s^2)');
title('VD Estimated x-Acceleration');
legend({'Truth', 'VD-KF'}, 'Location', 'best');

subplot(2, 2, 4);
plot(time, results.truth.acceleration(2, :), 'k-', 'LineWidth', 1.6);
hold on;
plot(time, squeeze(vd_result.state_estimates(6, :, 1)), 'Color', vd_result.style.color, 'LineWidth', 1.3);
add_boundary_lines(gca, cfg.plot.boundary_times);
grid on;
xlabel('Time / s');
ylabel('a_y / (m/s^2)');
title('VD Estimated y-Acceleration');
legend({'Truth', 'VD-KF'}, 'Location', 'best');

artifact = save_figure_artifact(fig, artifact, output_dir, cfg);
end

function table_artifacts = write_summary_tables(results, cfg, output_dir)
table_artifacts = struct();

if cfg.output.save_csv
    table_artifacts.leaderboard_csv = fullfile(output_dir, 'leaderboard.csv');
    table_artifacts.summary_csv = fullfile(output_dir, 'summary_metrics.csv');
    writetable(results.leaderboard.table, table_artifacts.leaderboard_csv);
    writetable(results.table, table_artifacts.summary_csv);
else
    table_artifacts.leaderboard_csv = '';
    table_artifacts.summary_csv = '';
end

if cfg.output.save_markdown
    table_artifacts.leaderboard_md = fullfile(output_dir, 'leaderboard.md');
    table_artifacts.summary_md = fullfile(output_dir, 'experiment_summary.md');
    write_markdown_leaderboard(results, table_artifacts.leaderboard_md);
    write_experiment_summary(results, cfg, table_artifacts.summary_md);
else
    table_artifacts.leaderboard_md = '';
    table_artifacts.summary_md = '';
end

table_artifacts.tuning_report = fullfile(output_dir, 'tuning_report.txt');
write_tuning_report(results, cfg, table_artifacts.tuning_report);
end

function write_markdown_leaderboard(results, md_path)
fid = fopen(md_path, 'w');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Leaderboard\n\n');
fprintf(fid, '| Rank | Algorithm | Pass All | Non-x | Non-y | Man-x | Man-y | Overall Pos RMSE | Runtime (s) |\n');
fprintf(fid, '| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |\n');

tbl = results.table;
for idx = 1:height(tbl)
    fprintf(fid, '| %d | %s | %s | %.2f | %.2f | %.2f | %.2f | %.2f | %.4f |\n', ...
        tbl.rank(idx), tbl.scheme_name{idx}, pass_to_text(tbl.pass_all(idx)), ...
        tbl.non_x_rmse(idx), tbl.non_y_rmse(idx), ...
        tbl.man_x_rmse(idx), tbl.man_y_rmse(idx), ...
        tbl.overall_pos_rmse(idx), tbl.runtime_seconds(idx));
end
end

function write_experiment_summary(results, cfg, md_path)
fid = fopen(md_path, 'w');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Experiment Summary\n\n');
fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- Sampling interval: %.2f s\n', cfg.scenario.dt);
fprintf(fid, '- Final time: %.2f s\n', cfg.scenario.t_end);
fprintf(fid, '- Monte Carlo trials: %d\n', cfg.measurement.num_mc);
fprintf(fid, '- Measurement covariance: [%.1f, %.1f; %.1f, %.1f]\n', ...
    cfg.measurement.R(1, 1), cfg.measurement.R(1, 2), ...
    cfg.measurement.R(2, 1), cfg.measurement.R(2, 2));
fprintf(fid, '- Non-maneuver axis threshold: %.1f m\n', cfg.evaluation.non_maneuver_axis_threshold);
fprintf(fid, '- Maneuver axis threshold: %.1f m\n', cfg.evaluation.maneuver_axis_threshold);

if isfield(results.tuning, 'imm_cv') && isfield(results.tuning.imm_cv, 'selected_candidate')
    selected = results.tuning.imm_cv.selected_candidate;
    fprintf(fid, '- Selected IMM q_list: [%.2e, %.2e, %.2e]\n', ...
        selected.q_list(1), selected.q_list(2), selected.q_list(3));
end
if isfield(results.tuning, 'singer_kf') && isfield(results.tuning.singer_kf, 'selected_candidate')
    fprintf(fid, '- Singer-KF tuning: %s\n', results.tuning.singer_kf.selected_candidate.candidate_name);
end
if isfield(results.tuning, 'ie_kf') && isfield(results.tuning.ie_kf, 'selected_candidate')
    fprintf(fid, '- IE-KF tuning: %s\n', results.tuning.ie_kf.selected_candidate.candidate_name);
end
if isfield(results.tuning, 'vd_kf') && isfield(results.tuning.vd_kf, 'selected_candidate')
    fprintf(fid, '- VD-KF tuning: %s\n', results.tuning.vd_kf.selected_candidate.candidate_name);
end

fprintf(fid, '\n## Ranking Notes\n\n');
for idx = 1:numel(results.leaderboard.entries)
    entry = results.leaderboard.entries(idx);
    fprintf(fid, '- #%d %s: pass_all=%s, total_excess=%.2f, overall_position_rmse=%.2f m, peak_position_rmse=%.2f m\n', ...
        entry.rank, entry.scheme_name, pass_to_text(entry.pass_all), entry.total_excess, ...
        entry.overall_position_rmse, entry.peak_position_rmse);
end

fprintf(fid, '\n## Recommended Figure Usage\n\n');
fprintf(fid, '- `trajectory_overview`: use for global motion comparison and first-run trajectory display.\n');
fprintf(fid, '- `rmse_overview`: use for time-varying RMSE comparison and peak/overall error comparison.\n');
fprintf(fid, '- `segment_scoreboard`: use for threshold discussion and runtime tradeoff.\n');
fprintf(fid, '- `maneuver_zoom`: use for focused maneuver-window analysis.\n');
fprintf(fid, '- `state_comparison`: use for explaining kinematic estimation behavior.\n');
fprintf(fid, '- `imm_diagnostics`, `ie_diagnostics`, `vd_diagnostics`: use for algorithm-specific mechanism discussion.\n');
end

function write_tuning_report(results, cfg, report_path)
fid = fopen(report_path, 'w');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Tracking Benchmark Tuning Report\n');
fprintf(fid, '================================\n\n');
fprintf(fid, 'Sampling interval: %.2f s\n', cfg.scenario.dt);
fprintf(fid, 'Final time: %.2f s\n', cfg.scenario.t_end);
fprintf(fid, 'Monte Carlo trials: %d\n\n', cfg.measurement.num_mc);

for idx = 1:numel(results.table.rank)
    fprintf(fid, '[%s]\n', results.table.scheme_name{idx});
    fprintf(fid, '  Non-maneuver axis RMSE: x = %.4f m, y = %.4f m\n', ...
        results.table.non_x_rmse(idx), results.table.non_y_rmse(idx));
    fprintf(fid, '  Maneuver axis RMSE: x = %.4f m, y = %.4f m\n', ...
        results.table.man_x_rmse(idx), results.table.man_y_rmse(idx));
    fprintf(fid, '  Overall position RMSE: %.4f m\n', results.table.overall_pos_rmse(idx));
    fprintf(fid, '  Runtime: %.4f s\n\n', results.table.runtime_seconds(idx));
end

if isfield(results.tuning, 'imm_cv') && isfield(results.tuning.imm_cv, 'selected_candidate')
    candidate = results.tuning.imm_cv.selected_candidate;
    fprintf(fid, '[IMM Auto Tuning]\n');
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

write_generic_tuning_section(fid, results.tuning, 'Singer Auto Tuning', 'singer_kf');
write_generic_tuning_section(fid, results.tuning, 'IE Auto Tuning', 'ie_kf');
write_generic_tuning_section(fid, results.tuning, 'VD Auto Tuning', 'vd_kf');
end

function names = get_scheme_names(algorithm_results)
names = cell(numel(algorithm_results), 1);
for idx = 1:numel(algorithm_results)
    names{idx} = algorithm_results(idx).scheme_name;
end
end

function figures = append_figure_artifact(figures, artifact)
figures(numel(figures) + 1, 1) = artifact;
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
    exportgraphics(fig, artifact.png, 'Resolution', 220);
end
if cfg.output.save_fig
    artifact.fig = fullfile(output_dir, [artifact.name, '.fig']);
    savefig(fig, artifact.fig);
end
end

function add_boundary_lines(ax, boundaries)
hold(ax, 'on');
current_limits = ylim(ax);
for idx = 1:numel(boundaries)
    plot(ax, [boundaries(idx), boundaries(idx)], current_limits, 'k:');
end
ylim(ax, current_limits);
end

function tf = has_nonzero_acceleration_content(algorithm_result)
accel_x = squeeze(algorithm_result.state_estimates(3, :, 1));
accel_y = squeeze(algorithm_result.state_estimates(6, :, 1));
tf = any(abs(accel_x) > 1.0e-12) || any(abs(accel_y) > 1.0e-12);
end

function text_out = pass_to_text(flag)
if flag
    text_out = 'YES';
else
    text_out = 'NO';
end
end

function write_generic_tuning_section(fid, tuning_struct, section_title, field_name)
if ~isfield(tuning_struct, field_name) || ~isfield(tuning_struct.(field_name), 'selected_candidate')
    return;
end

candidate = tuning_struct.(field_name).selected_candidate;
fprintf(fid, '\n[%s]\n', section_title);
fprintf(fid, 'Selected candidate index: %d\n', candidate.candidate_index);
fprintf(fid, 'Candidate label: %s\n', candidate.candidate_name);
fprintf(fid, 'Used trials: %d\n', candidate.used_trials);
fprintf(fid, 'Non-maneuver axis RMSE: [%.4f, %.4f] m\n', ...
    candidate.axis_non_maneuver(1), candidate.axis_non_maneuver(2));
fprintf(fid, 'Maneuver axis RMSE: [%.4f, %.4f] m\n', ...
    candidate.axis_maneuver(1), candidate.axis_maneuver(2));
fprintf(fid, 'Overall position RMSE: %.4f m\n', candidate.overall_position_rmse);
end
