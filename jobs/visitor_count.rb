require 'google/api_client'
require 'date'

def setup
  # Update these to match your own apps credentials
  config = YAML.load(File.open("config.yml"))
  service_account_email = config[:ga][:service_account_email]
  key_file = config[:ga][:key_file]
  key_secret = config[:ga][:key_secret]
  profileID = config[:ga][:profile_id]

  # Get the Google API client
  client = Google::APIClient.new(:application_name => '[YOUR APPLICATION NAME]', 
    :application_version => '0.01')

  # Load your credentials for the service account
  key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
  client.authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    :audience => 'https://accounts.google.com/o/oauth2/token',
    :scope => 'https://www.googleapis.com/auth/analytics.readonly',
    :issuer => service_account_email,
    :signing_key => key)
   client
end

# Start the scheduler
SCHEDULER.every '1m', :first_in => 0 do

  @client ||= setup
  client = @client
  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')

  # Start and end dates
  startDate = DateTime.now.strftime("%Y-%m-01") # first day of current month
  endDate = DateTime.now.strftime("%Y-%m-%d")  # now

  # Execute the query
  visitCount = client.execute(:api_method => analytics.data.ga.get, :parameters => { 
    'ids' => "ga:" + profileID, 
    'start-date' => startDate,
    'end-date' => endDate,
    # 'dimensions' => "ga:month",
    'metrics' => "ga:visitors",
    # 'sort' => "ga:month" 
  })

  # Update the dashboard
  # Note the trailing to_i - See: https://github.com/Shopify/dashing/issues/33
  send_event('visitor_count',   { current: visitCount.data.rows[0][0].to_i })
end
