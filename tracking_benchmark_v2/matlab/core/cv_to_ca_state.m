function x_ca = cv_to_ca_state(x_cv)
%CV_TO_CA_STATE Embed a 4D CV state into a 6D CA state.

x_ca = [x_cv(1); x_cv(2); 0; x_cv(3); x_cv(4); 0];
end
