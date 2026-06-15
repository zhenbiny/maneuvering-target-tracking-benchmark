function results = run_tracking_benchmark()
%RUN_TRACKING_BENCHMARK Entry point of the rebuilt benchmark platform.

project_root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(project_root, 'matlab')));

cfg = benchmark_config();
results = run_benchmark_study(cfg);
cfg = results.config;

display_benchmark_summary(results, cfg);
results.artifacts = plot_benchmark_results(results, cfg);
results.animations = export_all_animations(results, cfg);
end
