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
Settings.memcached[:ttl] ||= 1.minute

if Settings.memcached.host && Settings.memcached.port
  $cache ||= Memcached::Rails.new("#{Settings.memcached.host}:#{Settings.memcached.port}", logger: Rails.logger, default_ttl: Settings.memcached.ttl)
end

DROOM = Her::API.new
DROOM.setup url: "#{Settings.auth.protocol}://#{Settings.auth.host}:#{Settings.auth.port}/api" do |c|
  # Request
  c.use FaradayMiddleware::Caching, $cache.clone if $cache
  c.use Faraday::Request::UrlEncoded

  # Response
  c.use PaginatedHer::Middleware::Parser
  c.use Faraday::Adapter::NetHttp
end

