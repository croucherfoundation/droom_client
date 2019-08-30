require 'settingslogic'
require 'request_store'
require 'droom_client/engine'
require 'responders'

module DroomClient
  class AuthRequired < StandardError; end
end
