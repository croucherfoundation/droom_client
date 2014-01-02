require 'settings'
require 'paginated_her'

Settings.auth[:protocol] ||= 'http'
Settings.auth[:port] ||= '80'

DROOM = Her::API.new
DROOM.setup url: "#{Settings.auth.protocol}://#{Settings.auth.host}:#{Settings.auth.port}/api" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use PaginatedHer::Middleware::TokenAuth
  c.use PaginatedHer::Middleware::Parser
  c.use Faraday::Adapter::NetHttp
end

