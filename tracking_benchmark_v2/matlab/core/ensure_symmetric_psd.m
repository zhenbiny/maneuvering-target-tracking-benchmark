function covariance = ensure_symmetric_psd(covariance)
%ENSURE_SYMMETRIC_PSD Force covariance symmetry and remove tiny negatives.

covariance = 0.5 * (covariance + covariance');
[vectors, values] = eig(covariance);
diagonal_values = diag(values);
diagonal_values(diagonal_values < 1.0e-10) = 1.0e-10;
covariance = vectors * diag(diagonal_values) * vectors';
covariance = 0.5 * (covariance + covariance');
end
