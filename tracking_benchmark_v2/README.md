# Tracking Benchmark V2

## Overview

This project is a rebuilt maneuvering-target tracking benchmark that keeps the
original experiment untouched and provides a new comparison platform for
multiple classical algorithms.

The benchmark currently targets the following algorithms:

- `CA-KF`: constant-acceleration Kalman filter
- `Singer-KF`: Singer acceleration model Kalman filter
- `IE-KF`: input-estimation based maneuver tracker
- `VD-KF`: variable-dimension maneuver tracker
- `IMM-CV`: interacting multiple-model filter with constant-velocity submodels

The platform provides:

- unified truth and measurement generation
- unified Monte Carlo evaluation
- segment-wise threshold checking
- detailed static comparison figures
- combined and per-algorithm animations
- export of CSV and Markdown summary tables

## Structure

```text
tracking_benchmark_v2/
  run_tracking_benchmark.m
  README.md
  matlab/
    benchmark_config.m
    run_benchmark_study.m
    algorithms/
    core/
    evaluation/
    tuning/
    visualization/
  outputs/
```

## How To Run

Open MATLAB in this folder and run:

```matlab
clear functions
results = run_tracking_benchmark;
```

The benchmark will:

1. generate truth and noisy measurements
2. optionally tune the IMM configuration
3. run all enabled algorithms
4. evaluate the segment-wise RMSE metrics
5. export figures, tables, and animations to `outputs`

## Expected Outputs

After one run, the `outputs` folder will contain:

- static comparison figures such as
  - `trajectory_overview`
  - `rmse_overview`
  - `segment_scoreboard`
  - `maneuver_zoom`
  - `state_comparison`
  - `leaderboard_summary`
  - `imm_diagnostics`
  - `ie_diagnostics`
  - `vd_diagnostics`
- summary tables
  - `leaderboard.csv`
  - `summary_metrics.csv`
  - `leaderboard.md`
  - `experiment_summary.md`
  - `tuning_report.txt`
- animations
  - `comparison_animation.gif` and video
  - `grid_animation.gif` and video
  - `trajectory_<algorithm>.gif` and video for each enabled algorithm

## What To Check After Running

- confirm MATLAB prints the rebuilt benchmark summary without errors
- confirm `outputs` is created under `tracking_benchmark_v2`
- inspect whether the ranking order and threshold pass flags match expectation
- inspect the maneuver-window figures and animations first, because they are
  usually the most useful materials for the course report and presentation

## Notes

- The original project remains unchanged outside this folder.
- The IE and VD implementations in this benchmark are educational realizations
  of the classical ideas, intended for comparison and course discussion.
- Generated outputs in `outputs/` are ignored by Git in the public repository
  unless selected figures are intentionally curated for `docs/assets/`.
