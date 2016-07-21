notification(:tmux, {
  timeout: 0.1, # Just flash it
  display_message: true,
  display_title: true,
  default_message_color: 'black',
  # display_on_all_clients: true,
  success: 'colour22',
  failure: 'colour124',
  pending: 'colour166',
  color_location: %w[status-left-bg pane-active-border-fg pane-border-fg],
}) if ENV['TMUX']
