# Contributing Guide

Thanks for your interest in improving this repository.

## Scope

This project is a public MATLAB benchmark for maneuvering target tracking.
Useful contributions include:

- algorithm fixes and numerical-stability improvements
- cleaner experiment configuration and documentation
- better plotting, diagnostics, and result export
- reproducibility improvements
- benchmark extensions with clearly documented assumptions

## Before opening a pull request

1. Keep public content free of personal, institution-specific, or coursework-only information.
2. Preserve the separation between public repository files and ignored local-only materials under `private_local/`.
3. Avoid committing generated outputs from routine local runs unless they are intentionally curated public showcase assets in `docs/assets/`.
4. When changing an algorithm, update any comments or documentation needed to explain the modeling assumption.

## Recommended local verification

For the legacy experiment:

```matlab
clear functions
results = run_tracking_experiment;
```

For the rebuilt benchmark:

```matlab
clear functions
results = run_tracking_benchmark_from_root;
```

Check the following after your run:

- the MATLAB command window summary finishes without errors
- `tracking_benchmark_v2/outputs/` is regenerated as expected
- figures and tables are consistent with the new behavior
- no sensitive local files are staged for commit

## Style notes

- Prefer clear and stable MATLAB code over compact tricks.
- Keep helper logic in the most relevant subfolder such as `core/`, `evaluation/`, `tuning/`, or `visualization/`.
- Add short comments only where the numerical logic would otherwise be hard to follow.
- Preserve backward compatibility for the root entry points unless there is a strong reason to change them.

## Pull request expectations

A good pull request should describe:

- what changed
- why the change was needed
- whether the change affects metrics, ranking, or exported figures
- what local verification was performed
