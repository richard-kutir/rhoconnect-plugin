Rhoconnectrb.configure do |config|
  config.uri    = "http://localhost:9292"
  config.token  = "my-rhoconnect-token"
  config.app_endpoint = "http://localhost:3000"
  config.authenticate = lambda { |credentials|
    # User.authenticate(credentials[:login], credentials[:password])
    true
  }
end