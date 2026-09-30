# Full DCS-5 geometry and physics with the policy/reward interface used by the comparison.

full_current_density_max = ${fparse 1100.0/(pi*0.031^2)}

!include ../../../../tutorials/efas/introduction/dcs5_copper_constant_properties_electrothermal.i

[Functions]
  [current_fraction]
    type = ConstantFunction
    value = 0.0
  []
  [controlled_current_application]
    type = ParsedFunction
    expression = 'fraction*${full_current_density_max}'
    symbol_names = fraction
    symbol_values = current_fraction
  []
  [target_temperature]
    type = ParsedFunction
    expression = 'if(t < 80.0, 300.0 + 6.25*t, 800.0)'
  []
[]

[BCs]
  [electric_top]
    function := controlled_current_application
  []
[]

[Postprocessors]
  [pyrometer_temperature]
    type = PointValue
    variable = temperature
    point = '${fparse powder_radius + 0.004} ${fparse ram_cc_sinter_punch_height + powder_height / 2.0} 0'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [powder_average_temperature]
    type = ElementAverageValue
    variable = temperature
    block = powder
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [powder_max_temperature]
    type = ElementExtremeValue
    variable = temperature
    block = powder
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [powder_min_temperature]
    type = ElementExtremeValue
    variable = temperature
    block = powder
    value_type = min
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [powder_temperature_spread]
    type = ParsedPostprocessor
    expression = 'powder_max - powder_min'
    pp_names = 'powder_max_temperature powder_min_temperature'
    pp_symbols = 'powder_max powder_min'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [target_temperature]
    type = FunctionValuePostprocessor
    function = target_temperature
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [voltage_drop]
    type = SideAverageValue
    variable = potential
    boundary = top_ram_spacer_top
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [applied_current_density]
    type = FunctionValuePostprocessor
    function = controlled_current_application
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [normalized_action]
    type = LibtorchControlValuePostprocessor
    control_name = current_control
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [action_log_probability]
    type = LibtorchDRLLogProbabilityPostprocessor
    control_name = current_control
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reward]
    type = ParsedPostprocessor
    expression = '-4.0*((powder_average-target)/500.0)^2 - 1.0*(spread/150.0)^2 - 25.0*max(0.0,(powder_max-900.0)/100.0)^2 - 0.01*action^2'
    pp_names = 'powder_average_temperature target_temperature powder_temperature_spread powder_max_temperature normalized_action'
    pp_symbols = 'powder_average target spread powder_max action'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Reporters]
  [episode]
    type = AccumulateReporter
    reporters = 'pyrometer_temperature/value target_temperature/value voltage_drop/value powder_average_temperature/value powder_max_temperature/value powder_min_temperature/value powder_temperature_spread/value applied_current_density/value normalized_action/value action_log_probability/value reward/value'
  []
[]

[Controls]
  [current_control]
    type = LibtorchDRLControl
    parameters = 'Functions/current_fraction/value'
    observations = 'pyrometer_temperature target_temperature'
    input_timesteps = 3
    num_steps_in_period = 2
    observation_shift_factors = '300.0 300.0'
    observation_scaling_factors = '0.002 0.002'
    action_scaling_factors = 1.0
    min_control_value = 0.0
    max_control_value = 1.0
    control_smoothing_factor = 1.0
    stochastic = true
    seed = 1949
    execute_on = TIMESTEP_BEGIN
  []
[]

[UserObjects]
  [enforce_current_bounds]
    type = Terminator
    expression = '(normalized_action < -1.0e-8) | (normalized_action > 1.0000001)'
    message = 'Applied EFAS current fraction left its physical bounds.'
    execute_on = TIMESTEP_END
  []
[]

[Outputs]
  console = false
  csv := false
  exodus := false
  perf_graph := false
[]
