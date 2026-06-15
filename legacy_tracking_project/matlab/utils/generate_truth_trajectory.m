function truth = generate_truth_trajectory(cfg)
%GENERATE_TRUTH_TRAJECTORY Build the piecewise target motion.

time = 0:cfg.dt:cfg.t_end;
num_steps = numel(time);

position = zeros(2, num_steps);
velocity = zeros(2, num_steps);
acceleration = zeros(2, num_steps);

position(:, 1) = cfg.truth.initial_state([1, 4]);
velocity(:, 1) = cfg.truth.initial_state([2, 5]);

for k = 1:(num_steps - 1)
    accel_now = scenario_acceleration(time(k));
    acceleration(:, k) = accel_now;

    position(:, k + 1) = position(:, k) ...
        + velocity(:, k) * cfg.dt ...
        + 0.5 * accel_now * cfg.dt^2;
    velocity(:, k + 1) = velocity(:, k) + accel_now * cfg.dt;
end

acceleration(:, end) = scenario_acceleration(time(end));

truth = struct();
truth.time = time;
truth.position = position;
truth.velocity = velocity;
truth.acceleration = acceleration;
truth.state_ca = [
    position(1, :);
    velocity(1, :);
    acceleration(1, :);
    position(2, :);
    velocity(2, :);
    acceleration(2, :)
];
truth.segment_masks = build_segment_masks(time);
end

function accel = scenario_acceleration(current_time)
if current_time < 400
    accel = [0; 0];
elseif current_time < 600
    accel = [0.075; 0.075];
elseif current_time < 610
    accel = [0; 0];
elseif current_time < 660
    accel = [-0.3; -0.3];
else
    accel = [0; 0];
end
end
