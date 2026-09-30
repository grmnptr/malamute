open_loop_current_density = 2.75e6

!include sps_electrothermal_sub.i

[Functions]
  [open_loop_profile]
    type = ConstantFunction
    value = ${open_loop_current_density}
  []
[]

[Controls]
  inactive = current_control
  [open_loop_control]
    type = RealFunctionControl
    parameter = 'Functions/current_profile/value'
    function = open_loop_profile
    execute_on = 'INITIAL TIMESTEP_BEGIN'
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
    file_base = sps_open_loop_out
  []
[]
