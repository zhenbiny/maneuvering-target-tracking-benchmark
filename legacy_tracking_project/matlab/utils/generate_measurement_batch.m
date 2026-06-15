function measurements = generate_measurement_batch(truth, cfg)
%GENERATE_MEASUREMENT_BATCH Draw correlated Gaussian position measurements.

num_steps = numel(truth.time);
measurement_batch = zeros(2, num_steps, cfg.num_mc);

stream = RandStream('mt19937ar', 'Seed', cfg.random_seed);
chol_r = chol(cfg.measurement.R, 'lower');

for trial = 1:cfg.num_mc
    noise = chol_r * randn(stream, 2, num_steps);
    measurement_batch(:, :, trial) = truth.position + noise;
end

measurements = struct();
measurements.z = measurement_batch;
measurements.R = cfg.measurement.R;
measurements.first_run = measurement_batch(:, :, 1);
end
