require 'faraday'
require 'json'
require 'her'
require 'her/middleware/json_api_parser'

# Use CORE_API_URL for Supervisor
# api_url = ENV['CORE_API_URL']
api_url = "http://127.0.0.1:3000"

Client = Her::API.new
Client.setup url: api_url do |c|
  # Encode request payloads as JSON
  c.request :json
  c.use Her::Middleware::DefaultParseJSON
  # Parse responses as JSON API
  c.use Faraday::Response::Logger

  # Use default Faraday adapter
  c.adapter Faraday.default_adapter
end
