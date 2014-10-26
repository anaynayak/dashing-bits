# load the widget configuration
config = YAML.load File.open("config.yml")
config = config[:errbit]

SCHEDULER.every "5m", first_in: 0 do |job|
  projects = Errbit.new(config).projects
  send_event "errbit", { projects: projects}
end
