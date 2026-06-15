function [f_matrix, q_matrix] = discretize_lti_van_loan(a_matrix, g_matrix, qc_matrix, dt)
%DISCRETIZE_LTI_VAN_LOAN Discretize a continuous-time linear stochastic model.

state_dim = size(a_matrix, 1);
augmented = [
    -a_matrix, g_matrix * qc_matrix * g_matrix';
    zeros(state_dim), a_matrix'
] * dt;

transition = expm(augmented);
phi12 = transition(1:state_dim, (state_dim + 1):(2 * state_dim));
phi22 = transition((state_dim + 1):(2 * state_dim), (state_dim + 1):(2 * state_dim));

f_matrix = phi22';
q_matrix = f_matrix * phi12;
q_matrix = 0.5 * (q_matrix + q_matrix');
end
