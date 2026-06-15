function results = run_tracking_study(cfg)
%RUN_TRACKING_STUDY Run trajectory generation, filtering and evaluation.

truth = generate_truth_trajectory(cfg);
measurements = generate_measurement_batch(truth, cfg);

if isfield(cfg.imm, 'auto_tune') && cfg.imm.auto_tune
    [cfg.imm, tuning] = select_imm_configuration(measurements, truth, cfg);
else
    tuning = struct();
end

ca_batch = run_ca_kf_batch(measurements, cfg);
imm_batch = run_imm_cv_batch(measurements, cfg);

results = struct();
results.config = cfg;
results.tuning = tuning;
results.truth = truth;
results.measurements = measurements;
results.ca = evaluate_estimates(ca_batch, truth, cfg);
results.imm = evaluate_estimates(imm_batch, truth, cfg);
end
