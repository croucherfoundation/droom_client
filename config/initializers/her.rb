require 'faraday'
require 'json'
require 'her'
require 'her/middleware/json_api_parser'
require 'droom_client/middleware/envelope_parser'

api_url = ENV['DROOM_API_URL']

DROOM = Her::API.new
DROOM.setup url: api_url do |c|
  # Request: encode JSON manually
  c.request :json

  # Response: parse enveloped responses (success/message/<record>),
  # passing already JSON:API-shaped bodies through untouched.
  c.use DroomClient::Middleware::EnvelopeParser

  # Adapter
  c.adapter Faraday.default_adapter
end
