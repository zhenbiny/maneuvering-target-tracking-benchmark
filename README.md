# Maneuvering Target Tracking Benchmark

MATLAB benchmark for maneuvering target tracking under noisy 2D position
measurements. The repository contains a legacy experiment and an extended
multi-algorithm benchmark built on the same trajectory-generation and
evaluation idea.

![MATLAB](https://img.shields.io/badge/MATLAB-compatible-orange)
![Algorithms](https://img.shields.io/badge/algorithms-5-blue)
![License](https://img.shields.io/badge/license-MIT-green)

![Benchmark animation](docs/assets/comparison_animation.gif)

## Overview

This project focuses on comparing classical tracking methods on the same
maneuvering-target scenario.

- state and measurement generation are unified across algorithms
- segment-wise RMSE thresholds are used for evaluation
- static figures and animations are exported automatically after each run

The benchmark currently includes:

- `CA-KF`
- `Singer-KF`
- `IE-KF`
- `VD-KF`
- `IMM-CV`

## Quick Start

Open MATLAB in the repository root:

```matlab
cd('path_to_repository')
clear functions
```

Run the legacy experiment:

```matlab
results = run_tracking_experiment;
```

Run the rebuilt benchmark from the repository root:

```matlab
results = run_tracking_benchmark_from_root;
```

Run the rebuilt benchmark from its own folder:

```matlab
cd tracking_benchmark_v2
clear functions
results = run_tracking_benchmark;
```

## Repository Structure

```text
project_root/
|-- README.md
|-- run_tracking_experiment.m
|-- run_tracking_benchmark_from_root.m
|-- legacy_tracking_project/
|-- tracking_benchmark_v2/
`-- docs/
    |-- assets/
    |-- 01_presentation/
    |-- 02_report_materials/
    |-- 03_specifications/
    `-- 04_references/
```

- `run_tracking_experiment.m`: root entry for the legacy two-scheme experiment
- `run_tracking_benchmark_from_root.m`: root entry for the rebuilt benchmark
- `legacy_tracking_project/`: original implementation with CA-KF and IMM-CV
- `tracking_benchmark_v2/`: extended benchmark with unified evaluation,
  tuning, visualization, and animation export
- `docs/assets/`: figures and GIFs used by the project homepage
- `docs/01_presentation/`: presentation-related notes and reusable materials
- `docs/02_report_materials/`: report-oriented notes and writing support files
- `docs/03_specifications/`: scenario summary and benchmark settings
- `docs/04_references/`: reference list for the algorithms and related study

## Main Outputs

After running the rebuilt benchmark, `tracking_benchmark_v2/outputs/` typically
contains:

- trajectory comparison figures
- RMSE comparison figures
- maneuver-window zoom figures
- leaderboard tables in CSV and Markdown format
- per-algorithm animations in GIF and MP4 format

## Visual Snapshot

<p align="center">
  <img src="docs/assets/trajectory_overview.png" width="48%" alt="Trajectory overview" />
  <img src="docs/assets/maneuver_zoom.png" width="48%" alt="Maneuver window comparison" />
</p>

<p align="center">
  <img src="docs/assets/leaderboard_summary.png" width="70%" alt="Leaderboard summary" />
</p>

## Algorithms

| Algorithm | Core idea |
| --- | --- |
| `CA-KF` | Single constant-acceleration Kalman filter |
| `Singer-KF` | Correlated-acceleration model with smoothing support |
| `IE-KF` | Input-estimation-based maneuver tracking |
| `VD-KF` | Variable-dimension state switching |
| `IMM-CV` | Interactive multiple-model fusion with constant-velocity submodels |

## Benchmark Snapshot

The current public preview corresponds to a benchmark run with:

- sampling interval `10 s`
- final time `1000 s`
- `200` Monte Carlo trials
- non-maneuver threshold `50 m`
- maneuver threshold `150 m`

| Rank | Algorithm | Pass all thresholds | Overall position RMSE (m) | Runtime (s) |
| --- | --- | --- | ---: | ---: |
| 1 | `Singer-KF` | YES | 53.09 | 1.1125 |
| 2 | `IMM-CV` | YES | 77.46 | 2.0019 |
| 3 | `VD-KF` | NO | 102.09 | 0.9738 |
| 4 | `CA-KF` | NO | 95.88 | 0.3524 |
| 5 | `IE-KF` | NO | 142.21 | 1.1884 |

For the detailed benchmark implementation, see
`tracking_benchmark_v2/README.md`.
