function x_cv = ca_to_cv_state(x_ca)
%CA_TO_CV_STATE Project a 6D CA state onto a 4D CV state.

x_cv = [x_ca(1); x_ca(2); x_ca(4); x_ca(5)];
end
