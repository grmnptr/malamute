[StochasticTools]
[]

[Samplers]
  [environments]
    type = CartesianProduct
    linear_space_items = '0 0 ${training_num_environments}'
    min_procs_per_row = ${training_ranks_per_episode}
    max_procs_per_row = ${training_ranks_per_episode}
    execute_on = PRE_MULTIAPP_SETUP
  []
[]

[MultiApps]
  [episodes]
    type = SamplerFullSolveMultiApp
    sampler = environments
    input_files = ${training_episode_input}
    min_procs_per_app = ${training_ranks_per_episode}
    max_procs_per_app = ${training_ranks_per_episode}
    mode = batch-reset
  []
[]

[Transfers]
  [policy]
    type = SamplerDRLControlTransfer
    to_multi_app = episodes
    sampler = environments
    trainer_name = ppo
    control_name = current_control
  []
  [trajectories]
    type = SamplerReporterTransfer
    from_multi_app = episodes
    sampler = environments
    stochastic_reporter = storage
    from_reporter = 'episode/pyrometer_temperature:value episode/target_temperature:value episode/reward:value episode/normalized_action:value episode/action_log_probability:value'
  []
[]

[Trainers]
  [ppo]
    type = LibtorchDRLControlTrainer
    observation = 'storage/trajectories:episode:pyrometer_temperature:value storage/trajectories:episode:target_temperature:value'
    control = 'storage/trajectories:episode:normalized_action:value'
    log_probability = 'storage/trajectories:episode:action_log_probability:value'
    reward = 'storage/trajectories:episode:reward:value'

    filename_base = ${training_checkpoint_base}
    seed = 1949
    num_epochs = 10
    update_frequency = 1
    decay_factor = 0.99
    lambda_factor = 0.95
    clip_parameter = 0.2
    entropy_coeff = 0.005
    standardize_advantage = true
    batch_size = 128
    loss_print_frequency = 1

    critic_learning_rate = 1.0e-3
    num_critic_neurons_per_layer = '32 32'
    critic_activation_functions = 'relu relu'
    control_learning_rate = 3.0e-4
    num_control_neurons_per_layer = '32 32'
    control_activation_functions = 'relu relu'

    input_timesteps = 3
    timestep_window = 2
    average_reward_over_timestep_window = true
    observation_shift_factors = '300.0 300.0'
    observation_scaling_factors = '0.002 0.002'
    action_scaling_factors = 1.0
    min_control_value = 0.0
    max_control_value = 1.0
    shift_outputs = true
    read_from_file = false
  []
[]

[Reporters]
  [storage]
    type = StochasticReporter
    parallel_type = ROOT
    outputs = none
  []
  [training_reward]
    type = DRLRewardReporter
    drl_trainer_name = ppo
  []
[]

[Executioner]
  type = Transient
  num_steps = 100
[]

[Outputs]
  file_base = ${training_output_base}
  csv = true
  execute_on = TIMESTEP_END
[]

