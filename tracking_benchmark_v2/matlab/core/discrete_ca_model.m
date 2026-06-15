function [F, Q, H] = discrete_ca_model(dt, q)
%DISCRETE_CA_MODEL Build the 2D constant-acceleration discrete model.

f_axis = [1, dt, 0.5 * dt^2; 0, 1, dt; 0, 0, 1];
q_axis = q * [
    dt^5 / 20, dt^4 / 8, dt^3 / 6;
    dt^4 / 8, dt^3 / 3, dt^2 / 2;
    dt^3 / 6, dt^2 / 2, dt
];

F = blkdiag(f_axis, f_axis);
Q = blkdiag(q_axis, q_axis);
H = [
    1, 0, 0, 0, 0, 0;
    0, 0, 0, 1, 0, 0
];
end
