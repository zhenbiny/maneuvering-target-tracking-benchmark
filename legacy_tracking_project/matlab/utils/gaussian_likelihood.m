function likelihood = gaussian_likelihood(innovation, innovation_covariance)
%GAUSSIAN_LIKELIHOOD Multivariate Gaussian likelihood value.

dimension = numel(innovation);
[chol_s, chol_flag] = chol(innovation_covariance, 'lower');
if chol_flag ~= 0
    regularized_covariance = innovation_covariance + 1.0e-9 * eye(size(innovation_covariance));
    chol_s = chol(regularized_covariance, 'lower');
end

whitened_innovation = chol_s \ innovation;
log_det_s = 2 * sum(log(diag(chol_s)));
log_likelihood = -0.5 * ...
    (whitened_innovation' * whitened_innovation + log_det_s + dimension * log(2 * pi));
likelihood = max(exp(log_likelihood), realmin);
end
