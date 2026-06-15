function p_ca = cv_to_ca_covariance(p_cv, acceleration_variance)
%CV_TO_CA_COVARIANCE Embed a 4D CV covariance into a 6D CA covariance.

p_ca = zeros(6);
p_ca([1, 2, 4, 5], [1, 2, 4, 5]) = p_cv;
p_ca(3, 3) = acceleration_variance;
p_ca(6, 6) = acceleration_variance;
p_ca = ensure_symmetric_psd(p_ca);
end
