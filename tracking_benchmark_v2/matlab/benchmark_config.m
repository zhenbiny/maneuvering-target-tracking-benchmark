function cfg = benchmark_config()
%BENCHMARK_CONFIG Configuration for the rebuilt multi-algorithm benchmark.

project_root = fileparts(fileparts(mfilename('fullpath')));

cfg.project_root = project_root;
cfg.project_name = 'tracking_benchmark_v2';

cfg.scenario.dt = 10;
cfg.scenario.t_end = 1000;
cfg.scenario.initial_state_ca = [2000; 0; 0; 10000; -15; 0];

cfg.measurement.R = [1.0e4, 500; 500, 1.0e4];
cfg.measurement.num_mc = 200;
cfg.measurement.random_seed = 20260613;

cfg.experiment.use_known_initial_state = true;
cfg.experiment.enabled_algorithms = { ...
    'ca_kf', ...
    'singer_kf', ...
    'ie_kf', ...
    'vd_kf', ...
    'imm_cv' ...
};

cfg.evaluation.non_maneuver_axis_threshold = 50;
cfg.evaluation.maneuver_axis_threshold = 150;
cfg.evaluation.threshold_note = ...
    'Primary requirement uses segment-wise single-axis RMSE.';

cfg.algorithms.ca_kf.enabled = true;
cfg.algorithms.ca_kf.x0 = [2000; 0; 0; 10000; -15; 0];
cfg.algorithms.ca_kf.P0 = diag([10^2, 1^2, 0.05^2, 10^2, 1^2, 0.05^2]);
cfg.algorithms.ca_kf.q = 1.0e-4;

cfg.algorithms.singer_kf.enabled = true;
cfg.algorithms.singer_kf.x0 = [2000; 0; 0; 10000; -15; 0];
cfg.algorithms.singer_kf.P0 = diag([12^2, 1.5^2, 0.20^2, 12^2, 1.5^2, 0.20^2]);
cfg.algorithms.singer_kf.tau = 60;
cfg.algorithms.singer_kf.sigma_a = 0.12;
cfg.algorithms.singer_kf.use_rts_smoother = true;
cfg.algorithms.singer_kf.auto_tune = true;
cfg.algorithms.singer_kf.tuning.stage1_trials = 40;
cfg.algorithms.singer_kf.tuning.full_eval_candidates = 8;

cfg.algorithms.ie_kf.enabled = true;
cfg.algorithms.ie_kf.x0 = [2000; 0; 10000; -15];
cfg.algorithms.ie_kf.P0 = diag([12^2, 1.5^2, 12^2, 1.5^2]);
cfg.algorithms.ie_kf.q = 1.0e-6;
cfg.algorithms.ie_kf.window_length = 7;
cfg.algorithms.ie_kf.acceleration_decay = 0.94;
cfg.algorithms.ie_kf.initial_acceleration_std = 0.10;
cfg.algorithms.ie_kf.max_abs_input = 0.45;
cfg.algorithms.ie_kf.regularization = 1.0e-3;
cfg.algorithms.ie_kf.threshold_on = 1.8;
cfg.algorithms.ie_kf.threshold_off = 1.1;
cfg.algorithms.ie_kf.evidence_count_on = 2;
cfg.algorithms.ie_kf.evidence_count_off = 3;
cfg.algorithms.ie_kf.auto_tune = true;
cfg.algorithms.ie_kf.tuning.stage1_trials = 30;
cfg.algorithms.ie_kf.tuning.full_eval_candidates = 6;

cfg.algorithms.vd_kf.enabled = true;
cfg.algorithms.vd_kf.cv_x0 = [2000; 0; 10000; -15];
cfg.algorithms.vd_kf.cv_P0 = diag([10^2, 1^2, 10^2, 1^2]);
cfg.algorithms.vd_kf.cv_q = 3.0e-6;
cfg.algorithms.vd_kf.ca_x0 = [2000; 0; 0; 10000; -15; 0];
cfg.algorithms.vd_kf.ca_P0 = diag([10^2, 1^2, 0.25^2, 10^2, 1^2, 0.25^2]);
cfg.algorithms.vd_kf.ca_q = 5.0e-5;
cfg.algorithms.vd_kf.innovation_ema = 0.88;
cfg.algorithms.vd_kf.switch_up_threshold = 1.5;
cfg.algorithms.vd_kf.switch_up_nis_threshold = 5.0;
cfg.algorithms.vd_kf.switch_advantage_margin = 0.5;
cfg.algorithms.vd_kf.switch_down_threshold = 0.5;
cfg.algorithms.vd_kf.accel_release_threshold = 1.3;
cfg.algorithms.vd_kf.switch_back_advantage = 0.5;
cfg.algorithms.vd_kf.exit_hold_steps = 3;
cfg.algorithms.vd_kf.shadow_sync_ratio = 0.85;
cfg.algorithms.vd_kf.shadow_accel_decay = 0.82;
cfg.algorithms.vd_kf.inserted_acceleration_variance = 0.10^2;
cfg.algorithms.vd_kf.auto_tune = true;
cfg.algorithms.vd_kf.tuning.stage1_trials = 24;
cfg.algorithms.vd_kf.tuning.full_eval_candidates = 6;

cfg.algorithms.imm_cv.enabled = true;
cfg.algorithms.imm_cv.x0 = [2000; 0; 10000; -15];
cfg.algorithms.imm_cv.P0 = diag([10^2, 1^2, 10^2, 1^2]);
cfg.algorithms.imm_cv.mu0 = [0.85; 0.10; 0.05];
cfg.algorithms.imm_cv.q_list = [1.0e-6, 3.0e-4, 5.0e-1];
cfg.algorithms.imm_cv.transition_matrix = [
    0.98, 0.015, 0.005;
    0.02, 0.96, 0.02;
    0.005, 0.015, 0.98
];
cfg.algorithms.imm_cv.model_labels = {'Low maneuver', 'Medium maneuver', 'High maneuver'};
cfg.algorithms.imm_cv.auto_tune = true;
cfg.algorithms.imm_cv.tuning.stage1_trials = 60;
cfg.algorithms.imm_cv.tuning.full_eval_candidates = 8;

cfg.output.directory = fullfile(project_root, 'outputs');
cfg.output.save_png = true;
cfg.output.save_fig = true;
cfg.output.save_csv = true;
cfg.output.save_markdown = true;
cfg.output.export_animations = true;
cfg.output.animation_stride = 1;
cfg.output.animation_delay = 0.10;
cfg.output.export_per_algorithm_animations = true;
cfg.output.export_grid_animation = true;

cfg.plot.boundary_times = [400, 600, 610, 660];
end
