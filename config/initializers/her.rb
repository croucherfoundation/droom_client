require 'settings'
require 'paginated_her'
require 'dalli-elasticache'
require 'faraday_middleware/response/caching'

Settings[:auth] ||= {}
Settings.auth[:protocol] ||= 'http'
Settings.auth[:port] ||= '80'
Settings[:memcached] ||= {}
Settings.memcached[:endpoint] ||= nil
Settings.memcached[:host] ||= nil
Settings.memcached[:port] ||= 11211
Settings.memcached[:ttl] ||= 10.minutes

if Settings.memcached.endpoint
  elasticache_endpoint = Dalli::ElastiCache.new("#{Settings.memcached.endpoint}:#{Settings.memcached.port}", expires_in: Settings.memcached.ttl)
  $cache ||= elasticache_endpoint.client

elsif Settings.memcached.host
  $cache ||= Dalli::Client.new("#{Settings.memcached.host}:#{Settings.memcached.port}", expires_in: Settings.memcached.ttl)
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

