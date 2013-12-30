require 'settings'
require 'paginated_authorized_her'

DROOM = Her::API.new base_uri: "#{Settings.droom.protocol}://#{Settings.droom.host}/api" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use PaginatedAuthorizedHer::Middleware::TokenAuth
  c.use PaginatedAuthorizedHer::Middleware::Parser
  c.use Faraday::Adapter::NetHttp
end

