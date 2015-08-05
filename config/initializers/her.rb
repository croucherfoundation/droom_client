require 'settings'
require 'faraday_middleware'
require 'her'
require 'her/middleware/json_api_parser'

Settings[:auth] ||= {}
Settings.auth[:protocol] ||= 'http'
Settings.auth[:port] ||= '80'

DROOM = Her::API.new
DROOM.setup url: "#{Settings.auth.protocol}://#{Settings.auth.host}:#{Settings.auth.port}" do |c|
  # Request
  c.use FaradayMiddleware::EncodeJson
  # Response
  c.use Her::Middleware::JsonApiParser
  c.use Faraday::Adapter::NetHttp
end

