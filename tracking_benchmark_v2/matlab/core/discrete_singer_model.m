function [F, Q, H] = discrete_singer_model(dt, tau, sigma_a)
%DISCRETE_SINGER_MODEL Discretized 2D Singer acceleration model.

alpha = 1 / max(tau, eps);
A_axis = [
    0, 1, 0;
    0, 0, 1;
    0, 0, -alpha
];
G_axis = [0; 0; 1];
Qc_axis = 2 * alpha * sigma_a^2;

[F_axis, Q_axis] = discretize_lti_van_loan(A_axis, G_axis, Qc_axis, dt);

F = blkdiag(F_axis, F_axis);
Q = blkdiag(Q_axis, Q_axis);
H = [
    1, 0, 0, 0, 0, 0;
    0, 0, 0, 1, 0, 0
];
end
