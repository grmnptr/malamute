[StochasticTools]
[]

training_iterations = 200
parallel_rollouts = 2
rollout_steps = 43

drl_control_period_steps = 2
drl_action_smoother = 0.2
drl_action_scale = 1.0
drl_min_power = 0.0
drl_max_power = 0.42

[Samplers]
  [rollouts]
    type = CartesianProduct
    linear_space_items = '0 1 ${parallel_rollouts}'
    execute_on = 'INITIAL PRE_MULTIAPP_SETUP'
  []
[]

[MultiApps]
  [runner]
    type = SamplerFullSolveMultiApp
    sampler = rollouts
    input_files = 'thermal_drl.i'
    mode = batch-reset
    cli_args = "Outputs/active='';Outputs/console=false;drl_control_period_steps=${drl_control_period_steps};drl_action_smoother=${drl_action_smoother};drl_action_scale=${drl_action_scale};drl_min_power=${drl_min_power};drl_max_power=${drl_max_power};Executioner/num_steps=${rollout_steps}"
  []
[]

[Transfers]
  [nn_transfer]
    type = SamplerDRLControlTransfer
    to_multi_app = runner
    trainer_name = nn_trainer
    control_name = laser_power_control
    sampler = rollouts
  []
  [r_transfer]
    type = SamplerReporterTransfer
    from_multi_app = runner
    sampler = rollouts
    stochastic_reporter = storage
    from_reporter = 'drl_policy_data/time_normalized:value
                     drl_policy_data/pass_fraction:value
                     drl_policy_data/laser_x_normalized:value
                     drl_policy_data/laser_z_normalized:value
                     drl_policy_data/laser_target_region:value
                     drl_policy_data/laser_gap_region:value
                     drl_policy_data/target_volume_normalized:value
                     drl_policy_data/gap_volume_normalized:value
                     drl_policy_data/bead_height_normalized:value
                     drl_policy_data/temperature_error:value
                     drl_policy_data/laser_power_policy_action:value
                     drl_policy_data/laser_power_log_probability:value
                     drl_policy_data/reward:value
                     drl_policy_data/reward_instant:value
                     drl_policy_data/bead_max_temperature:value
                     drl_policy_data/bead_volume:value
                     drl_policy_data/target_bead_volume:value
                     drl_policy_data/gap_bead_volume:value'
  []
[]

[Trainers]
  [nn_trainer]
    type = LibtorchDRLControlTrainer
    observation = 'storage/r_transfer:drl_policy_data:time_normalized:value
                   storage/r_transfer:drl_policy_data:pass_fraction:value
                   storage/r_transfer:drl_policy_data:laser_x_normalized:value
                   storage/r_transfer:drl_policy_data:laser_z_normalized:value
                   storage/r_transfer:drl_policy_data:laser_target_region:value
                   storage/r_transfer:drl_policy_data:laser_gap_region:value
                   storage/r_transfer:drl_policy_data:target_volume_normalized:value
                   storage/r_transfer:drl_policy_data:gap_volume_normalized:value
                   storage/r_transfer:drl_policy_data:bead_height_normalized:value
                   storage/r_transfer:drl_policy_data:temperature_error:value'
    control = 'storage/r_transfer:drl_policy_data:laser_power_policy_action:value'
    log_probability = 'storage/r_transfer:drl_policy_data:laser_power_log_probability:value'
    reward = 'storage/r_transfer:drl_policy_data:reward:value'

    input_timesteps = 2
    observation_shift_factors = '0 0 0 0 0 0 0 0 0 0'
    observation_scaling_factors = '1 1 1 1 1 1 1 1 1 1'
    action_scaling_factors = ${drl_action_scale}
    min_control_value = ${drl_min_power}
    max_control_value = ${drl_max_power}

    num_epochs = 5
    update_frequency = 2

    decay_factor = 0.99
    lambda_factor = 0.97
    clip_parameter = 0.2
    timestep_window = ${drl_control_period_steps}
    average_reward_over_timestep_window = false

    critic_learning_rate = 0.001
    num_critic_neurons_per_layer = '64 64'
    critic_activation_functions = 'relu relu'

    control_learning_rate = 0.0005
    num_control_neurons_per_layer = '64 64'
    control_activation_functions = 'relu relu'

    standardize_advantage = true
    batch_size = 128
    entropy_coeff = 0.01
    filename_base = 'one_gap_wall_drl'
    read_from_file = false
  []
[]

[Reporters]
  [storage]
    type = StochasticReporter
    parallel_type = ROOT
    outputs = none
  []
  [reward]
    type = DRLRewardReporter
    drl_trainer_name = nn_trainer
  []
[]

[Executioner]
  type = Transient
  num_steps = ${training_iterations}
[]

[Outputs]
  checkpoint = false
  [json]
    type = JSON
    file_base = 'output/train_one_gap'
    time_step_interval = 1
    execute_on = TIMESTEP_END
  []
[]
