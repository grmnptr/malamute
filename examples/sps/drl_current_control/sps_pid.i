!include sps_electrothermal_sub.i

[Controls]
  inactive = current_control
  [pid]
    type = PIDTransientControl
    postprocessor = pyrometer_temperature
    target = target_temperature
    parameter = 'Functions/current_profile/value'
    K_proportional = -2.0e4
    K_integral = -100.0
    K_derivative = 0.0
    minimum_output_value = 0.0
    maximum_output_value = ${current_density_max}
    maximum_change_rate = 2.5e5
    reset_integral_windup = true
    execute_on = TIMESTEP_BEGIN
  []
[]

[Postprocessors]
  inactive = 'normalized_action action_log_probability'
[]

[Reporters]
  inactive = episode
[]

[Outputs]
  [csv]
    type = CSV
    file_base = sps_pid_out
  []
[]
