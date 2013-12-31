require 'settings'
require 'paginated_her'

DROOM = Her::API.new base_uri: "#{Settings.droom.protocol}://#{Settings.droom.host}/api" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use PaginatedHer::Middleware::TokenAuth
  c.use PaginatedHer::Middleware::Parser
  c.use Faraday::Adapter::NetHttp
end

