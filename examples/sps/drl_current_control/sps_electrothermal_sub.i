# Reduced axisymmetric EFAS episode used by open-loop, PID, PPO training, and evaluation runs.
# SI units are used throughout.

initial_temperature = 300.0
episode_length = 120.0
physics_dt = 2.0
current_density_max = 1.0e7
powder_electrical_multiplier = 1.0

[Mesh]
  [base]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0.0
    xmax = 0.012
    ymin = 0.0
    ymax = 0.030
    nx = 8
    ny = 18
    subdomain_ids = 4
  []
  [lower_punch]
    type = SubdomainBoundingBoxGenerator
    input = base
    bottom_left = '0.0 0.0 0.0'
    top_right = '0.006 0.010 0.0'
    block_id = 1
    block_name = lower_punch
  []
  [powder]
    type = SubdomainBoundingBoxGenerator
    input = lower_punch
    bottom_left = '0.0 0.010 0.0'
    top_right = '0.006 0.020 0.0'
    block_id = 2
    block_name = powder
  []
  [upper_punch]
    type = SubdomainBoundingBoxGenerator
    input = powder
    bottom_left = '0.0 0.020 0.0'
    top_right = '0.006 0.030 0.0'
    block_id = 3
    block_name = upper_punch
  []
  [rename_die]
    type = RenameBlockGenerator
    input = upper_punch
    old_block = 4
    new_block = die
  []
  [top_electrode]
    type = SideSetsFromBoundingBoxGenerator
    input = rename_die
    included_boundaries = top
    bottom_left = '-1e-9 0.028 -1e-9'
    top_right = '0.006001 0.030001 1e-9'
    boundary_new = top_electrode
  []
  [bottom_electrode]
    type = SideSetsFromBoundingBoxGenerator
    input = top_electrode
    included_boundaries = bottom
    bottom_left = '-1e-9 -1e-9 -1e-9'
    top_right = '0.006001 0.002 1e-9'
    boundary_new = bottom_electrode
  []
  coord_type = RZ
[]

[Variables]
  [temperature]
    initial_condition = ${initial_temperature}
  []
  [electric_potential]
  []
[]

[Kernels]
  [temperature_time]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = specific_heat
    density_name = density
  []
  [temperature_diffusion]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = thermal_conductivity
  []
  [joule_heating]
    type = ADJouleHeatingSource
    variable = temperature
    elec = electric_potential
    electrical_conductivity = electrical_conductivity
  []
  [electric_conduction]
    type = ADMatDiffusion
    variable = electric_potential
    diffusivity = electrical_conductivity
  []
[]

[Functions]
  [current_profile]
    type = ConstantFunction
    value = 0.0
  []
  [ambient_temperature]
    type = ConstantFunction
    value = 300.0
  []
  [surface_emissivity]
    type = ConstantFunction
    value = 0.80
  []
  [target_temperature]
    type = ParsedFunction
    expression = 'if(t < 80.0, 300.0 + 6.25*t, 800.0)'
  []
[]

[BCs]
  [electric_top]
    type = ADFunctionNeumannBC
    variable = electric_potential
    boundary = top_electrode
    function = current_profile
  []
  [electric_bottom]
    type = ADDirichletBC
    variable = electric_potential
    boundary = bottom_electrode
    value = 0.0
  []
  [die_radiation]
    type = ADFunctionRadiativeBC
    variable = temperature
    boundary = right
    emissivity_function = surface_emissivity
    Tinfinity = ambient_temperature
  []
[]

[Materials]
  [graphite_thermal]
    type = ADParsedMaterial
    block = 'lower_punch upper_punch die'
    property_name = thermal_conductivity
    coupled_variables = temperature
    expression = 'max(55.0, 115.0 - 0.025*(temperature - 300.0))'
  []
  [graphite_electrical]
    type = ADParsedMaterial
    block = 'lower_punch upper_punch die'
    property_name = electrical_conductivity
    coupled_variables = temperature
    expression = '1.0 / max(8.0e-6, 1.813e-5 - 1.836e-8*temperature + 1.263e-11*temperature^2 - 2.705e-15*temperature^3)'
  []
  [graphite_capacity]
    type = ADGenericConstantMaterial
    block = 'lower_punch upper_punch die'
    prop_names = 'density specific_heat'
    prop_values = '1750.0 710.0'
  []
  [powder_thermal]
    type = ADParsedMaterial
    block = powder
    property_name = thermal_conductivity
    coupled_variables = temperature
    expression = 'max(18.0, 28.0 - 0.008*(temperature - 300.0))'
  []
  [powder_electrical]
    type = ADParsedMaterial
    block = powder
    property_name = electrical_conductivity
    coupled_variables = temperature
    constant_names = conductivity_multiplier
    constant_expressions = ${powder_electrical_multiplier}
    expression = 'conductivity_multiplier * 1.0e6 / (1.0 + 0.0015*(temperature - 300.0))'
  []
  [powder_capacity]
    type = ADGenericConstantMaterial
    block = powder
    prop_names = 'density specific_heat'
    prop_values = '5300.0 500.0'
  []
[]

[Postprocessors]
  [pyrometer_temperature]
    type = SideAverageValue
    variable = temperature
    boundary = right
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
    variable = electric_potential
    boundary = top_electrode
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [applied_current_density]
    type = FunctionValuePostprocessor
    function = current_profile
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
    expression = '-4.0*((powder_average-target)/500.0)^2 - 1.0*(spread/150.0)^2 - 25.0*max(0.0,(powder_max-900.0)/100.0)^2 - 0.01*(current/${current_density_max})^2'
    pp_names = 'powder_average_temperature target_temperature powder_temperature_spread powder_max_temperature applied_current_density'
    pp_symbols = 'powder_average target spread powder_max current'
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
    parameters = 'Functions/current_profile/value'
    observations = 'pyrometer_temperature target_temperature voltage_drop'
    input_timesteps = 3
    num_steps_in_period = 2
    observation_shift_factors = '300.0 300.0 0.0'
    observation_scaling_factors = '0.002 0.002 1.0'
    action_scaling_factors = ${current_density_max}
    min_control_value = 0.0
    max_control_value = 1.0
    smoother = 1.0
    stochastic = true
    seed = 1949
    execute_on = TIMESTEP_BEGIN
  []
[]

[UserObjects]
  [enforce_current_bounds]
    type = Terminator
    expression = '(applied_current_density < -1.0e-8) | (applied_current_density > 1.0000001*${current_density_max})'
    message = 'Applied EFAS current density left its physical bounds.'
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  automatic_scaling = true
  line_search = none
  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-7
  nl_max_its = 20
  l_max_its = 50
  dt = ${physics_dt}
  end_time = ${episode_length}
[]

[Outputs]
  console = false
[]
