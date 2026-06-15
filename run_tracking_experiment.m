function results = run_tracking_experiment()
%RUN_TRACKING_EXPERIMENT Compatibility entry for the legacy tracking study.

project_root = fileparts(mfilename('fullpath'));
legacy_root = fullfile(project_root, 'legacy_tracking_project');
addpath(genpath(fullfile(legacy_root, 'matlab')));

cfg = tracking_config();
results = run_tracking_study(cfg);
cfg = results.config;

display_summary(results, cfg);
results.artifacts = plot_tracking_results(results, cfg);
end
