function cfg = tracking_config()
%TRACKING_CONFIG Default configuration for the course experiment.

cfg.dt = 10;
cfg.t_end = 1000;
cfg.num_mc = 200;
cfg.random_seed = 20260607;
cfg.use_known_initial_state = true;

cfg.truth.initial_state = [2000; 0; 0; 10000; -15; 0];
cfg.measurement.R = [1.0e4, 500; 500, 1.0e4];

cfg.evaluation.non_maneuver_axis_threshold = 50;
cfg.evaluation.maneuver_axis_threshold = 150;
cfg.evaluation.threshold_note = ...
    'Thresholds are checked against per-axis RMSE by default.';

cfg.ca.x0 = [2000; 0; 0; 10000; -15; 0];
cfg.ca.P0 = diag([10^2, 1^2, 0.05^2, 10^2, 1^2, 0.05^2]);
cfg.ca.q = 1.0e-4;

cfg.imm.x0 = [2000; 0; 10000; -15];
cfg.imm.P0 = diag([10^2, 1^2, 10^2, 1^2]);
cfg.imm.mu0 = [0.85; 0.10; 0.05];
cfg.imm.q_list = [1.0e-6, 3.0e-4, 5.0e-1];
cfg.imm.transition_matrix = [
    0.98, 0.015, 0.005;
    0.02, 0.96, 0.02;
    0.005, 0.015, 0.98
];
cfg.imm.model_labels = {'Low maneuver', 'Medium maneuver', 'High maneuver'};
cfg.imm.auto_tune = true;
cfg.imm.tuning.stage1_trials = 60;
cfg.imm.tuning.full_eval_candidates = 8;

cfg.plot.boundary_times = [400, 600, 610, 660];

project_root = fileparts(fileparts(mfilename('fullpath')));
cfg.output.directory = fullfile(project_root, 'outputs');
cfg.output.save_png = true;
cfg.output.save_fig = true;
cfg.output.export_animation = true;
cfg.output.animation_stride = 1;
cfg.output.animation_delay = 0.10;
end
