require 'httparty'
require 'digest/md5'

def translate_status_to_class(status)
  statuses = {
    'success' => 'passed',
      'fixed' => 'passed',
    'running' => 'pending',
     'failed' => 'failed'
  }
  statuses[status.downcase] || 'pending'
end

def update_build(project)
  data = {
    name: "#{project['name']}",
    label: "#{project['lastBuildLabel']}",
    widget_class: "#{translate_status_to_class(project['lastBuildStatus'])}"
  }
  return data
end

def update_builds(gocd_server)
  api_url = gocd_server
  api_response =  HTTParty.get(api_url, :basic_auth => {:username => ENV['CI_USER'], :password => ENV['CI_PASSWORD']}, :format => :xml)
  response = api_response.parsed_response
  return {} if response.empty?
  response["Projects"]["Project"].collect{ |p| update_build(p)}
end

SCHEDULER.every '10s', :first_in => 0  do
  gocd_server = YAML.load(File.open("config.yml"))[:gocd][:url]
  items = update_builds(gocd_server)
  send_event('gocd', { items: items })
end
