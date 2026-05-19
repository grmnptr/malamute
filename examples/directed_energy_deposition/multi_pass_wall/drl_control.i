drl_control_period_steps = 4
drl_action_smoother = 0.35
drl_min_power = 0.18
drl_max_power = 0.42
drl_action_scale = 1.0
drl_target_temperature = 1950
drl_temperature_scale = 300
drl_expected_volume = 12

[Postprocessors]
  [time_normalized]
    type = ParsedPostprocessor
    expression = 't/3560'
    use_t = true
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [pass_fraction]
    type = ParsedPostprocessor
    expression = 'if(t<920, 0, if(t<1840, 0.333333333, if(t<2760, 0.666666667, 1)))'
    use_t = true
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_on]
    type = ParsedPostprocessor
    expression = 'if(t<=800, 1, if(t<=920, 0, if(t<=1720, 1, if(t<=1840, 0, if(t<=2640, 1, if(t<=2760, 0, 1))))))'
    use_t = true
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_x]
    type = FunctionValuePostprocessor
    function = heat_source_x
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_x_normalized]
    type = ParsedPostprocessor
    pp_names = 'laser_x'
    pp_symbols = 'x_laser'
    expression = 'x_laser/2'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_z]
    type = FunctionValuePostprocessor
    function = heat_source_z
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_z_normalized]
    type = ParsedPostprocessor
    pp_names = 'laser_z'
    pp_symbols = 'z_laser'
    expression = '(z_laser - 0.85)/0.3'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [bead_volume_normalized]
    type = ParsedPostprocessor
    pp_names = 'bead_volume'
    pp_symbols = 'volume'
    expression = 'volume / ${drl_expected_volume}'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [bead_height_normalized]
    type = ParsedPostprocessor
    pp_names = 'bead_z_coord_max'
    pp_symbols = 'height'
    expression = '(height - 0.6)/1.2'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [temperature_error]
    type = ParsedPostprocessor
    pp_names = 'bead_max_temperature'
    pp_symbols = 'Tmax'
    expression = '(Tmax - ${drl_target_temperature}) / ${drl_temperature_scale}'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [laser_power_policy_action]
    type = LibtorchControlValuePostprocessor
    control_name = laser_power_control
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [laser_power_log_probability]
    type = LibtorchDRLLogProbabilityPostprocessor
    control_name = laser_power_control
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reward_instant]
    type = ParsedPostprocessor
    pp_names = 'temperature_error bead_volume_normalized laser_power_policy_action'
    pp_symbols = 'temp_error volume_norm power_action'
    expression = '-temp_error*temp_error - 0.25*if(volume_norm<0.05, (0.05-volume_norm)*(0.05-volume_norm), 0) - 0.05*((power_action-0.3)/0.12)*((power_action-0.3)/0.12)'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reward]
    type = ParsedPostprocessor
    pp_names = 'reward_instant'
    pp_symbols = 'r'
    expression = 'r'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Controls]
  [laser_power_control]
    type = LibtorchDRLControl
    parameters = 'Materials/volumetric_heat_metal/power'
    observations = 'time_normalized pass_fraction laser_on laser_x_normalized laser_z_normalized
                    bead_volume_normalized bead_height_normalized temperature_error'

    input_timesteps = 2
    observation_shift_factors = '0 0 0 0 0 0 0 0'
    observation_scaling_factors = '1 1 1 1 1 1 1 1'
    action_scaling_factors = ${drl_action_scale}
    min_control_value = ${drl_min_power}
    max_control_value = ${drl_max_power}

    num_steps_in_period = ${drl_control_period_steps}
    smoother = ${drl_action_smoother}
    stochastic = true

    execute_on = 'TIMESTEP_BEGIN'
  []
[]

[Reporters]
  [drl_policy_data]
    type = AccumulateReporter
    reporters = 'time_normalized/value pass_fraction/value laser_on/value
                 laser_x_normalized/value laser_z_normalized/value
                 bead_volume_normalized/value bead_height_normalized/value temperature_error/value
                 laser_power_policy_action/value laser_power_log_probability/value
                 reward/value reward_instant/value bead_max_temperature/value bead_volume/value'
  []
[]
