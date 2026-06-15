function [state_smooth, covariance_smooth] = ...
    rts_smooth_sequence(F, state_filtered, covariance_filtered, state_predicted, covariance_predicted)
%RTS_SMOOTH_SEQUENCE Rauch-Tung-Striebel backward smoothing.

num_steps = size(state_filtered, 2);
state_smooth = state_filtered;
covariance_smooth = covariance_filtered;

for k = (num_steps - 1):-1:1
    prediction_covariance = ensure_symmetric_psd(covariance_predicted(:, :, k + 1));
    smoothing_gain = (covariance_filtered(:, :, k) * F') / prediction_covariance;

    state_smooth(:, k) = state_filtered(:, k) + ...
        smoothing_gain * (state_smooth(:, k + 1) - state_predicted(:, k + 1));
    covariance_smooth(:, :, k) = ensure_symmetric_psd( ...
        covariance_filtered(:, :, k) + ...
        smoothing_gain * (covariance_smooth(:, :, k + 1) - prediction_covariance) * smoothing_gain');
end
end
