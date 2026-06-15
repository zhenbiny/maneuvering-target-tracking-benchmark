function [F, Q, B, H] = discrete_cv_model(dt, q)
%DISCRETE_CV_MODEL Build the 2D constant-velocity discrete model.

f_axis = [1, dt; 0, 1];
q_axis = q * [
    dt^3 / 3, dt^2 / 2;
    dt^2 / 2, dt
];
b_axis = [0.5 * dt^2; dt];

F = blkdiag(f_axis, f_axis);
Q = blkdiag(q_axis, q_axis);
B = [
    b_axis(1), 0;
    b_axis(2), 0;
    0, b_axis(1);
    0, b_axis(2)
];
H = [
    1, 0, 0, 0;
    0, 0, 1, 0
];
end
