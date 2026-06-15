# Scenario Summary

This repository uses a two-dimensional maneuvering target tracking scenario.

## Core setup

- Initial position: `(2000 m, 10000 m)`
- Initial velocity: `(0 m/s, -15 m/s)`
- Sampling interval: `10 s`
- Final time: `1000 s`
- Measurement type: noisy 2D position observations
- Monte Carlo trials in the default benchmark: `200`

## Motion profile

The target contains both non-maneuvering and maneuvering segments.

- Early stage: straight motion
- First maneuver: slow coordinated turn / mild acceleration segment
- Short transition interval
- Second maneuver: stronger turn / stronger acceleration segment
- Late stage: post-maneuver motion

## Evaluation rule

The benchmark primarily checks segment-wise single-axis RMSE:

- non-maneuver threshold: `50 m`
- maneuver threshold: `150 m`

Additional summary metrics include:

- segment-wise position RMSE
- overall position RMSE
- peak time-wise position RMSE

This public summary replaces the original local assignment PDF, which is kept
outside the repository.
