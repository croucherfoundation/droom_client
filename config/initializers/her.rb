require 'settings'
require 'faraday_middleware'
require 'her'
require 'her/middleware/json_api_parser'

api_url = ENV['DROOM_API_URL'] || "#{Settings.auth.protocol}://#{Settings.auth.host}:#{Settings.auth.port}"

DROOM = Her::API.new
DROOM.setup url: api_url do |c|
  # Request
  c.use FaradayMiddleware::EncodeJson
  # Response
  c.use Her::Middleware::JsonApiParser
  c.use Faraday::Adapter::NetHttp
end

