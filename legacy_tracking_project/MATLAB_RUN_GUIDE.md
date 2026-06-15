# MATLAB Tracking Experiment Guide

## Files

- `run_tracking_experiment.m`: experiment entry point
- `matlab/filters/run_ca_kf_batch.m`: scheme A, constant-acceleration Kalman filter
- `matlab/filters/run_imm_cv_batch.m`: scheme B, IMM with three constant-velocity models
- `matlab/utils/*`: trajectory generation, measurements, evaluation and plots

## Default assumptions

- Sampling interval: `10 s`
- Final simulation time: `1000 s`
- Monte Carlo trials: `200`
- Initial state handling: treat the given initial position and velocity as known, so no measurement update is applied at `t = 0`
- Measurement covariance:

```matlab
R = [10000, 500;
      500, 10000];
```

- Evaluation masks:
  - non-maneuver: `[0, 400)`, `[600, 610)`, `[660, t_end]`
  - maneuver: `[400, 600)`, `[610, 660)`

## How to run

Open MATLAB in the project root and execute:

```matlab
clear functions
results = run_tracking_experiment;
```

The default configuration now enables IMM auto-tuning, so the run may take longer than before.

## What you will get

- trajectory comparison figure
- RMSE comparison figure
- IMM model probability curves
- command window summary for both schemes
- an `outputs` folder with multiple PNG/FIG figures
- a trajectory animation GIF
- an MP4 animation if `VideoWriter` is available in your MATLAB

## Parameters worth tuning first

- `cfg.num_mc`
- `cfg.t_end`
- `cfg.ca.q`
- `cfg.imm.q_list`
- `cfg.imm.transition_matrix`
- `cfg.imm.auto_tune`
- `cfg.output.export_animation`

All of them are defined in `matlab/tracking_config.m`.
