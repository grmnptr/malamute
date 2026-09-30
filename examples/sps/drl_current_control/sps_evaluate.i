checkpoint = efas_current_control.net_best

[StochasticTools]
[]

[Samplers]
  [one_case]
    type = CartesianProduct
    linear_space_items = '0 0 1'
    execute_on = PRE_MULTIAPP_SETUP
  []
[]

[MultiApps]
  [episode]
    type = SamplerFullSolveMultiApp
    sampler = one_case
    input_files = sps_electrothermal_sub.i
    cli_args = "Controls/current_control/filename='${checkpoint}';Controls/current_control/num_neurons_per_layer='32 32';Controls/current_control/activation_function='relu relu';Controls/current_control/stochastic=false"
    mode = batch-reset
  []
[]

[Transfers]
  [metrics]
    type = SamplerPostprocessorTransfer
    from_multi_app = episode
    sampler = one_case
    to_vector_postprocessor = results
    from_postprocessor = 'pyrometer_temperature powder_average_temperature powder_max_temperature powder_min_temperature powder_temperature_spread target_temperature voltage_drop applied_current_density reward'
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
  file_base = sps_evaluate_out
  execute_on = FINAL
  csv = true
  json = true
[]
