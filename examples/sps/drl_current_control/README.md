# EFAS current control with PPO

This example is a lightweight, two-dimensional axisymmetric EFAS control problem. It retains a
graphite die, two graphite punches, and a powder compact, and solves transient heat conduction
coupled to quasi-static electric conduction and Joule heating. The die exterior radiates to a
300 K environment.

The actuator is current density on the upper punch. Its physical range is 0 to `1e7 A/m^2`, which
corresponds to approximately 0 to 1131 A through the 6 mm radius punch. The controller observes
only die-wall pyrometer temperature, target temperature, and upper-electrode voltage. The target
ramps from 300 K to 800 K over 80 s and then holds. PPO uses three observation times, updates its
action every two 2 s physics steps, and uses a bounded beta policy. The reward penalizes powder
tracking error, powder nonuniformity, temperatures above 900 K, and current use.

Run from this directory in the `moose-torch` environment:

```bash
../../../malamute-opt -i sps_open_loop.i
../../../malamute-opt -i sps_pid.i
../../../malamute-opt -i sps_train.i
../../../malamute-opt -i sps_evaluate.i checkpoint=efas_current_control.net_best
```

The application must be built with `STOCHASTIC_TOOLS := yes` and a libtorch-enabled MOOSE. The
current MALAMUTE Makefile already enables that module. `malamute-opt --show-capabilities` should
list both `stochastictoolsapp` and `libtorch`. The MOOSE source must also contain the bounded DRL
work from PR #32802 (including `SamplerDRLControlTransfer`, `timestep_window`, and
`min_control_value`/`max_control_value`). When using a separate MOOSE worktree, build and test with
that path explicitly, for example:

```bash
MOOSE_DIR=/path/to/moose/drl-mods make -j8
MOOSE_DIR=/path/to/moose/drl-mods ./run_tests --re drl_current_control -j1
```

`sps_train.i` defaults to eight identical nominal environments and 100 PPO updates. For a local
smoke run, override the sampler to two environments, the executioner to two updates, and PPO to two
epochs as done by `tests`. Large training runs are intended for the HPC system.

The first deliverable is nominal control. `powder_electrical_multiplier` is exposed at the top of
the episode input for later uncertain-material sampling. Because this first model uses conformal
interfaces, it has no independent contact-conductance parameter; contact uncertainty should be
added only when the conformal interfaces are replaced by a fixed-conductance formulation.

Nominal open-loop calibration gave final powder-average temperatures of 729 K at `2.5e6 A/m^2`
and 856 K at `3.0e6 A/m^2`. The default `2.75e6 A/m^2` is therefore a useful open-loop reference,
while the full actuator range remains available to PID and PPO. The initial PID gains give a
35 K ramp-and-hold RMSE, a peak powder temperature of 842 K, and a final temperature of 791 K.
