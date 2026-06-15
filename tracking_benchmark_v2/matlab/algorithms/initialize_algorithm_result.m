function result = initialize_algorithm_result(num_steps, num_trials)
%INITIALIZE_ALGORITHM_RESULT Create a uniform result container.

style = struct('color', [0, 0, 0], 'line_style', '-', 'marker', 'none');

result = struct();
result.scheme_id = '';
result.scheme_name = '';
result.scheme_category = '';
result.style = style;
result.runtime_seconds = NaN;

result.state_estimates = zeros(6, num_steps, num_trials);
result.position_estimates = zeros(2, num_steps, num_trials);
result.state_covariances_first = zeros(6, 6, num_steps);

result.model_probabilities = [];
result.mode_probability = [];
result.mode_index = [];
result.detector_score = [];
result.input_estimates = [];
result.innovation_norm = [];

result.diagnostics = struct();
result.metrics = struct();
end
