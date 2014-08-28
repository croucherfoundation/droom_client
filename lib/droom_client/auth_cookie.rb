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

    def set(resource, options={})
      Rails.logger.debug("AuthCookie.set resource ##{resource.uid}")
      @cookies[cookie_name] = cookie_options.merge(options).merge(:value => encoded_value(resource))
    end

    def unset(options={})
      @cookies.delete cookie_name, cookie_options.merge(options)
    end

    def token
      values[0]
    end

    def created_at
      valid? ? Time.at(value[1]) : nil
    end

    def valid?
      Rails.logger.debug("AuthCookie.valid? #{present?.inspect}, #{values.all?.inspect}")
      present? && values.all?
    end

    def present?
      @cookies[cookie_name].present?
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