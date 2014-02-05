require 'settings'
require 'paginated_her'
require 'memcached'
require 'faraday_middleware/response/caching'

Settings[:auth] ||= {}
Settings.auth[:protocol] ||= 'http'
Settings.auth[:port] ||= '80'
Settings[:memcached] ||= {}
Settings.memcached[:host] ||= nil
Settings.memcached[:port] ||= nil

DROOM = Her::API.new
DROOM.setup url: "#{Settings.auth.protocol}://#{Settings.auth.host}:#{Settings.auth.port}/api" do |c|
  # Request
  c.use FaradayMiddleware::Caching, Memcached::Rails.new("#{Settings.memcached.host}:#{Settings.memcached.port}") if Settings.memcached.host && Settings.memcached.port
  c.use Faraday::Request::UrlEncoded

  # Response
  c.use PaginatedHer::Middleware::Parser
  c.use Faraday::Adapter::NetHttp
end

