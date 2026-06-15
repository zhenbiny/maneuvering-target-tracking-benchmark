function subset = slice_measurements(measurements, trial_indices)
%SLICE_MEASUREMENTS Take a subset of Monte Carlo measurement realizations.

subset = measurements;
subset.z = measurements.z(:, :, trial_indices);
if isfield(measurements, 'first_run')
    subset.first_run = subset.z(:, :, 1);
end
end
