require 'settings'
require 'paginated_her'

DROOM = Her::API.new
DROOM.setup url: "#{Settings.droom.protocol}://#{Settings.droom.host}/api" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use PaginatedHer::Middleware::TokenAuth
  c.use PaginatedHer::Middleware::Parser
  c.use Faraday::Adapter::NetHttp
end

