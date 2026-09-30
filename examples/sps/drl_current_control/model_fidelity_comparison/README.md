# Full-versus-simplified EFAS policy comparison

These cases compare two PPO controllers while holding the policy architecture, observations,
action bounds, reward, target, time step, and evaluation model fixed:

1. Train on the full DCS-5 model and evaluate on the full DCS-5 model.
2. Train on the simplified model and evaluate on the full DCS-5 model.

Both controllers observe the die-wall pyrometer temperature and the 300-to-800 K target. Both emit
a dimensionless current fraction in `[0, 1]`. The simplified and full episodes convert that fraction
to their own current-density boundary values, corresponding to the same approximately 0-to-1100 A
physical actuator range. This keeps the saved actor networks directly interchangeable.

The full episode includes the corrected original tutorial input rather than copying or simplifying
its geometry, materials, or mortar interfaces. Training and evaluation disable field output.

## Build on HPC

Use a dedicated checkout of the `drl-mods` branch and keep libtorch inside that checkout. Replace
the two paths below with the corresponding HPC paths.

```bash
conda activate moose-torch
export MOOSE_DIR=/path/to/moose-drl-mods
export MALAMUTE_DIR=/path/to/malamute
export LIBTORCH_DIR="$MOOSE_DIR/framework/contrib/pytorch/installed"

git -C "$MOOSE_DIR" switch drl-mods
git -C "$MOOSE_DIR" pull --ff-only origin drl-mods

cd "$MOOSE_DIR"
if [ ! -f "$LIBTORCH_DIR/lib/libtorch.so" ]; then
  scripts/update_and_rebuild_libtorch.sh
fi

./configure --with-libtorch="$LIBTORCH_DIR"
make -C framework -j8
make -C modules/stochastic_tools -j8

cd "$MALAMUTE_DIR"
MOOSE_DIR="$MOOSE_DIR" make -j8

# Ensure that runtime loading uses the same libtorch used for compilation.
export LD_LIBRARY_PATH="$LIBTORCH_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

Before submitting the long jobs, verify that `malamute-opt --show-capabilities` reports
`stochastictoolsapp = true` and a `libtorch` version.

## HPC runs

Activate the `moose-torch` environment and run from this directory. The defaults use eight training
environments. A full-model environment uses eight MPI ranks, while a simplified environment uses
one rank.

```bash
conda activate moose-torch

# Eight full-model environments, eight ranks each (64 ranks total)
mpirun -n 64 ../../../../malamute-opt -i train_full.i

# Eight simplified environments, one rank each (8 ranks total)
mpirun -n 8 ../../../../malamute-opt -i train_simplified.i

# Evaluate each best checkpoint on the full model using eight ranks
mpirun -n 8 ../../../../malamute-opt -i evaluate_full_trained.i
mpirun -n 8 ../../../../malamute-opt -i evaluate_simplified_trained.i
```

For a 24-rank allocation, use three full-model environments. For a strict sample-for-sample
comparison, train the simplified controller with the same three environments and 100 PPO updates:

```bash
mpirun -n 24 ../../../../malamute-opt -i train_full.i \
  --allow-unused training_num_environments=3

mpirun -n 3 ../../../../malamute-opt -i train_simplified.i \
  --allow-unused training_num_environments=3
```

The simplified run needs only three ranks in that matched configuration; assigning it 24 ranks would
change the number of trajectories collected per PPO update. The full-model evaluation should remain
at eight ranks: 12 and 16 ranks passed one-step checks locally, but a 24-rank partition did not solve.

The primary outputs are `comparison_full_control.net_best`,
`comparison_simplified_control.net_best`, and the two `evaluate_*_out` CSV/JSON result files. The
JSON files contain the complete time histories needed for tracking, uniformity, safety, and current
comparisons; the CSV files contain the final metrics.

The executable must load the same libtorch release used to build MOOSE. If macOS finds a different
libtorch in the active conda environment first, prepend the configured MOOSE libtorch directory to
`DYLD_LIBRARY_PATH` (use `LD_LIBRARY_PATH` on Linux) before launching.
