# Simplified EFAS episode configured to use the same policy interface and time grid as the
# full DCS-5 episode.

episode_length := 1800
physics_dt := 6

!include ../sps_electrothermal_sub.i

[Functions]
  [current_fraction]
    type = ConstantFunction
    value = 0.0
  []
  [comparison_current_profile]
    type = ParsedFunction
    expression = 'fraction*${current_density_max}'
    symbol_names = fraction
    symbol_values = current_fraction
  []
[]

[BCs]
  [electric_top]
    function := comparison_current_profile
  []
[]

[Postprocessors]
  [applied_current_density]
    function := comparison_current_profile
  []
  [reward]
    expression := '-4.0*((powder_average-target)/500.0)^2 - 1.0*(spread/150.0)^2 - 25.0*max(0.0,(powder_max-900.0)/100.0)^2 - 0.01*action^2'
    pp_names := 'powder_average_temperature target_temperature powder_temperature_spread powder_max_temperature normalized_action'
    pp_symbols := 'powder_average target spread powder_max action'
  []
[]

[Controls]
  [current_control]
    parameters := 'Functions/current_fraction/value'
    observations := 'pyrometer_temperature target_temperature'
    observation_shift_factors := '300.0 300.0'
    observation_scaling_factors := '0.002 0.002'
    action_scaling_factors := 1.0
  []
[]
