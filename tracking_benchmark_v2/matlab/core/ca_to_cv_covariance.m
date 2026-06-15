function p_cv = ca_to_cv_covariance(p_ca)
%CA_TO_CV_COVARIANCE Project a 6D CA covariance onto a 4D CV covariance.

p_cv = p_ca([1, 2, 4, 5], [1, 2, 4, 5]);
p_cv = ensure_symmetric_psd(p_cv);
end
