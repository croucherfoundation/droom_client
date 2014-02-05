require 'settingslogic'
require 'request_store'
require 'memcached'
require 'droom_client/engine'

module DroomClient
  class AuthRequired < StandardError; end

end
