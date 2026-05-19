drl_control_period_steps = 2
drl_action_smoother = 0.2
drl_min_power = 0.0
drl_max_power = 0.42
drl_nominal_power = 0.3
drl_action_scale = 1.0
drl_target_temperature = 1900
drl_temperature_scale = 300
drl_expected_target_volume = 8
drl_expected_gap_volume = 2

[Postprocessors]
  [time_normalized]
    type = ParsedPostprocessor
    expression = 't/${end_time}'
    use_t = true
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [pass_fraction]
    type = ParsedPostprocessor
    expression = 'if(t<920, 0, 1)'
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
    expression = '(z_laser - 0.65)/0.1'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_target_region]
    type = ParsedPostprocessor
    pp_names = 'laser_x'
    pp_symbols = 'x_laser'
    expression = 'if(x_laser < -0.6, 1, if(x_laser > 0.6, 1, 0))'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [laser_gap_region]
    type = ParsedPostprocessor
    pp_names = 'laser_target_region'
    pp_symbols = 'target'
    expression = '1 - target'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [target_volume_normalized]
    type = ParsedPostprocessor
    pp_names = 'target_bead_volume'
    pp_symbols = 'volume'
    expression = 'volume / ${drl_expected_target_volume}'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gap_volume_normalized]
    type = ParsedPostprocessor
    pp_names = 'gap_bead_volume'
    pp_symbols = 'volume'
    expression = 'volume / ${drl_expected_gap_volume}'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [bead_height_normalized]
    type = ParsedPostprocessor
    pp_names = 'bead_z_coord_max'
    pp_symbols = 'height'
    expression = '(height - 0.6)/0.4'
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
    pp_names = 'laser_target_region laser_gap_region target_volume_normalized gap_volume_normalized temperature_error laser_power_policy_action'
    pp_symbols = 'in_target in_gap target_volume gap_volume temp_error power_action'
    expression = '0.2*target_volume - 1.0*gap_volume - 0.4*in_gap*(power_action/${drl_max_power})*(power_action/${drl_max_power}) - 0.15*in_target*((power_action-${drl_nominal_power})/0.12)*((power_action-${drl_nominal_power})/0.12) - 0.1*in_target*temp_error*temp_error'
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
    observations = 'time_normalized pass_fraction laser_x_normalized laser_z_normalized
                    laser_target_region laser_gap_region target_volume_normalized
                    gap_volume_normalized bead_height_normalized temperature_error'

    input_timesteps = 2
    observation_shift_factors = '0 0 0 0 0 0 0 0 0 0'
    observation_scaling_factors = '1 1 1 1 1 1 1 1 1 1'
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
    reporters = 'time_normalized/value pass_fraction/value laser_x_normalized/value laser_z_normalized/value
                 laser_target_region/value laser_gap_region/value target_volume_normalized/value
                 gap_volume_normalized/value bead_height_normalized/value temperature_error/value
                 laser_power_policy_action/value laser_power_log_probability/value reward/value reward_instant/value
                 bead_max_temperature/value bead_volume/value target_bead_volume/value gap_bead_volume/value'
  []
[]
