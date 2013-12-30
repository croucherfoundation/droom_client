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

    # Sets the cookie, referencing the given resource.id (e.g. User)
    def set(resource, options={})
      @cookies[cookie_name] = cookie_options.merge(options).merge(:value => encoded_value(resource))
    end

    # Unsets the cookie via the HTTP response.
    def unset(options={})
      @cookies.delete cookie_name, cookie_options.merge(options)
    end

    def token
      values[0]
    end

    # The Time at which the cookie was created.
    def created_at
      valid? ? Time.at(value[1]) : nil
    end

    # Whether the cookie appears valid.
    def valid?
      present? && values.all?
    end

    def present?
      @cookies[cookie_name].present?
    end

    # Whether the cookie was set since the given Time
    def set_since?(time)
      created_at && created_at >= time
    end
    
    def inspect
      values.inspect
    end

  private
    
    # cookie value format is [uid, auth_token, time]
    #
    def values
      begin
        signer.decode(@cookies[cookie_name])
      rescue SignedJson::Error
        [nil, nil]
      end
    end

    def cookie_name
      Settings.auth.cookie_name
    end

    def encoded_value(resource)
      signer.encode [ resource.authentication_token, Time.now ]
    end

    def cookie_options
      @session_options ||= Rails.configuration.session_options
      @session_options[:domain] = Settings.auth.cookie_domain
      @session_options.slice(:path, :domain, :secure, :httponly)
    end

    def signer
      secret = Settings.auth.secret
      @signer ||= SignedJson::Signer.new(secret)
    end

  end
end