require 'request_store'
require 'droom_client/engine'
require 'responders'
require 'droom_client/safe_html_sanitizer'

module DroomClient
  class AuthRequired < StandardError; end
end
