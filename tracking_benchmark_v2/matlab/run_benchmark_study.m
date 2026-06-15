function results = run_benchmark_study(cfg)
%RUN_BENCHMARK_STUDY Run the unified multi-algorithm comparison.

truth = generate_truth_trajectory(cfg);
measurements = generate_measurement_batch(truth, cfg);

tuning = struct();
if cfg.algorithms.singer_kf.enabled && cfg.algorithms.singer_kf.auto_tune
    [cfg.algorithms.singer_kf, tuning.singer_kf] = ...
        select_singer_configuration(measurements, truth, cfg);
end

if cfg.algorithms.ie_kf.enabled && cfg.algorithms.ie_kf.auto_tune
    [cfg.algorithms.ie_kf, tuning.ie_kf] = ...
        select_ie_configuration(measurements, truth, cfg);
end

if cfg.algorithms.vd_kf.enabled && cfg.algorithms.vd_kf.auto_tune
    [cfg.algorithms.vd_kf, tuning.vd_kf] = ...
        select_vd_configuration(measurements, truth, cfg);
end

if cfg.algorithms.imm_cv.enabled && cfg.algorithms.imm_cv.auto_tune
    [cfg.algorithms.imm_cv, tuning.imm_cv] = ...
        select_imm_configuration(measurements, truth, cfg);
end

registry = build_algorithm_registry(cfg);
enabled_mask = [registry.enabled] & ismember({registry.id}, cfg.experiment.enabled_algorithms);
registry = registry(enabled_mask);

algorithm_results = repmat(initialize_algorithm_result(numel(truth.time), cfg.measurement.num_mc), numel(registry), 1);
for idx = 1:numel(registry)
    alg = registry(idx);
    alg_cfg = cfg.algorithms.(alg.id);

    tic;
    batch = feval(alg.runner, measurements, truth, alg_cfg, cfg);
    elapsed_seconds = toc;

    batch.scheme_id = alg.id;
    batch.scheme_name = alg.name;
    batch.scheme_category = alg.category;
    batch.style = alg.style;
    batch.runtime_seconds = elapsed_seconds;

    algorithm_results(idx) = evaluate_estimates(batch, truth, cfg);
end

leaderboard = build_leaderboard(algorithm_results, cfg);

results = struct();
results.config = cfg;
results.truth = truth;
results.measurements = measurements;
results.registry = registry;
results.algorithms = algorithm_results;
results.tuning = tuning;
results.leaderboard = leaderboard;
results.table = build_results_table(algorithm_results, leaderboard, cfg);
results.named = struct();
for idx = 1:numel(algorithm_results)
    results.named.(algorithm_results(idx).scheme_id) = algorithm_results(idx);
end
end
