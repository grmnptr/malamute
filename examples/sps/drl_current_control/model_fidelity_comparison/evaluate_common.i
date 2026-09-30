[StochasticTools]
[]

[Samplers]
  [one_case]
    type = CartesianProduct
    linear_space_items = '0 0 1'
    min_procs_per_row = ${evaluation_ranks}
    max_procs_per_row = ${evaluation_ranks}
    execute_on = PRE_MULTIAPP_SETUP
  []
[]

[MultiApps]
  [episode]
    type = SamplerFullSolveMultiApp
    sampler = one_case
    input_files = full_episode.i
    cli_args = "Executioner/end_time=${evaluation_end_time};Controls/current_control/filename='${evaluation_checkpoint}';Controls/current_control/num_neurons_per_layer='32 32';Controls/current_control/activation_function='relu relu';Controls/current_control/stochastic=false"
    min_procs_per_app = ${evaluation_ranks}
    max_procs_per_app = ${evaluation_ranks}
    mode = batch-reset
  []
[]

[Transfers]
  [trajectories]
    type = SamplerReporterTransfer
    from_multi_app = episode
    sampler = one_case
    stochastic_reporter = trajectory_storage
    from_reporter = 'episode/pyrometer_temperature:value episode/target_temperature:value episode/powder_average_temperature:value episode/powder_max_temperature:value episode/powder_min_temperature:value episode/powder_temperature_spread:value episode/voltage_drop:value episode/applied_current_density:value episode/normalized_action:value episode/reward:value'
  []
  [metrics]
    type = SamplerPostprocessorTransfer
    from_multi_app = episode
    sampler = one_case
    to_vector_postprocessor = results
    from_postprocessor = 'pyrometer_temperature powder_average_temperature powder_max_temperature powder_min_temperature powder_temperature_spread target_temperature voltage_drop applied_current_density normalized_action reward'
  []
[]

[Reporters]
  [trajectory_storage]
    type = StochasticReporter
    parallel_type = ROOT
    outputs = json
  []
[]

[VectorPostprocessors]
  [results]
    type = StochasticResults
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  file_base = ${evaluation_output_base}
  execute_on = FINAL
  csv = true
  json = true
[]
