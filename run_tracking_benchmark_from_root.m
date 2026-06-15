function results = run_tracking_benchmark_from_root()
%RUN_TRACKING_BENCHMARK_FROM_ROOT Root-level shortcut for benchmark v2.

project_root = fileparts(mfilename('fullpath'));
benchmark_root = fullfile(project_root, 'tracking_benchmark_v2');
addpath(genpath(fullfile(benchmark_root, 'matlab')));

cfg = benchmark_config();
results = run_benchmark_study(cfg);
cfg = results.config;

display_benchmark_summary(results, cfg);
results.artifacts = plot_benchmark_results(results, cfg);
results.animations = export_all_animations(results, cfg);
end
