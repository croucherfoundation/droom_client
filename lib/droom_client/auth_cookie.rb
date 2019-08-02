# Loosely based from devise-login-cookie but adapted for our authentication situation.
# In droom we've also pinched the devise strategy but here we are a relatively dumb satellite
# with no independent user class.

require 'signed_json'
require "active_support/core_ext/hash/slice"

module DroomClient
  class AuthCookie

    def initialize(cookies)
      @cookies = cookies
    end

    def set(resource, opts={})
      cookie = cookie_options.merge(opts).merge(:value => encoded_value(resource))
      Rails.logger.warn "🔫 droom_client.set will assign new cookie time value: #{cookie.inspect}"
      @cookies[cookie_name] = cookie
    end

    def unset(opts={})
      @cookies.delete cookie_name, cookie_options.merge(opts)
    end

    def token
      values[0]
    end

    def created_at
      dt = DateTime.parse(values[1]) if valid?
      Rails.logger.warn "🔫 created_at: #{dt.inspect}"
      dt
    end

    def valid?
      present? && values.all?
    end

    def present?
      @cookies[cookie_name].present?
    end

    def fresh?
      set_since?(Time.now - cookie_lifespan.minutes)
    end

    def set_since?(time)
      created_at && created_at >= time
    end
    
    def inspect
      values.inspect
    end

  private

    # cookie value format is [auth_token, time]
    #
    def values
      begin
        signer.decode(@cookies[cookie_name])
      rescue SignedJson::Error
        [nil, nil]
      end
    end

    def cookie_name
      ENV['DROOM_AUTH_COOKIE'] || Settings.auth.cookie_name
    end

    def cookie_domain
      ENV['DROOM_AUTH_COOKIE_DOMAIN'] || Settings.auth.cookie_domain
    end

    def auth_secret
      ENV['DROOM_AUTH_SECRET'] || Settings.auth.secret
    end

    def cookie_lifespan
      (ENV['DROOM_AUTH_COOKIE_EXPIRY'] || Settings.auth.cookie_period).to_i
    end

    def encoded_value(resource)
      signer.encode [resource.unique_session_id, Time.now]
    end

    def cookie_options
      @session_options ||= Rails.configuration.session_options
      @session_options[:domain] = cookie_domain
      @session_options.slice(:path, :domain, :secure, :httponly)
    end

    def signer
      @signer ||= SignedJson::Signer.new(auth_secret)
    end

  end
end