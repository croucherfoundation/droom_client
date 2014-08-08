require 'settingslogic'
require 'request_store'
require 'dalli-elasticache'
require 'droom_client/engine'

module DroomClient
  class AuthRequired < StandardError; end
end
