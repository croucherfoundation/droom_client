# Here we extract a small part of the authorize-or-redirect functionality normally
# provided by devise or authlogic. No need for the full paraphernalia because we
# don't manage users here; only user sessions. All we have to do is consult the data
# room and remember the response. As well as the local session we stash it in a cross-
# domain cookie for basic SSO support.
#
# The actual consultation is done by our User resource class.
#
# This is separated out as a concern in order that it can be shared between several
# satellite applications. This and other shared functionality like the Her extensions
# will end up in their own gem once it all settles down.

require 'droom_client/auth_cookie'

module DroomAuthentication
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Token::ControllerMethods

  mattr_accessor :navigational_formats
  @@navigational_formats = ["*/*", :html]

  included do
    helper_method :current_user
    helper_method :user_signed_in?
    rescue_from DroomClient::AuthRequired, with: :redirect_to_login
    # rescue_from Her::Unauthorized, with: :redirect_to_login
    # rescue_from Her::Errors::Unauthorized, with: :redirect_to_login
  end

  def store_location!
    session["user_return_to"] = request.path
  end

  def use_stored_location_for(user)
    session.delete("user_return_to")
  end

  def stored_location_for(user)
    session["user_return_to"]
  end

  def default_location_for(user)
    root_path
  end

  def after_sign_in_path_for(user)
    path = use_stored_location_for(user) || default_location_for(user)
    path = root_path if path == droom_client.sign_in_path
    path
  end
  
  def after_sign_out_path_for(user)
    root_path
  end
  
  def after_user_update_path_for(user)
    root_path
  end

  def is_navigational_format?
    DroomAuthentication.navigational_formats.include?(request_format)
  end

  def request_format
    @request_format ||= request.format.try(:ref)
  end

protected
  
  ## Authentication filters
  #
  # Use in controllers to require various states of authentication.

  def require_authenticated_user
    raise DroomClient::AuthRequired, 'require_authenticated_user fails'unless authenticate_user
  end

  def authenticate_user!
    raise DroomClient::AuthRequired, 'authenticate_user! fails' unless authenticate_user
  end

  def require_user!
    raise DroomClient::AuthRequired, 'require_user! fails' unless user_signed_in?
  end

  def require_admin!
    raise DroomClient::AuthRequired, 'require_admin! fails' unless user_signed_in? && current_user.admin?
  end

  def require_no_user!
    if user_signed_in?
      flash[:error] = I18n.t(:already_signed_in)
      redirect_to after_sign_in_path_for(current_user)
    end
  end

  def redirect_to_login(exception)
    Rails.logger.warn "🔫 redirect_to_login: #{exception.message.inspect}"
    store_location!
    if is_navigational_format?
      if pjax?
        if signup_permitted?
          render partial: 'user_sessions/sign_in_or_up'
        else
          render partial: 'user_sessions/sign_in'
        end
      else
        sign_in_path = droom_client.sign_in_path
        dcmp = Settings.droom_client_mount_point
        sign_in_path = dcmp + sign_in_path unless sign_in_path =~ /^#{dcmp}/
        redirect_to sign_in_path
      end
    else
      Settings.auth['realm'] ||= 'Data Room'
      request_http_token_authentication(Settings.auth.realm)
    end
  end

  ## Stored Authentication
  # is always by auth_token. It can be given as header token, param or cookie.
  #
  def authenticate_user
    unless user_signed_in?
      if user = authenticate_from_header || authenticate_from_param || authenticate_from_cookie
        sign_in_and_remember(user)
      end
    end
    user_signed_in?
  end

  # Sometimes the satellite services provide their own API services. Usually these are very simple,
  # but they too might require droom authentication. In that case we require a header token and 
  # a uid in the options hash.
  #
  def authenticate_from_header
    authenticate_with_http_token do |token, options|
      authenticate_with(token) if token
    end
  end

  def authenticate_from_param
    if params[:tok].present?
      authenticate_with(params[:tok])
    end
  end
  
  def authenticate_from_cookie
    cookie = DroomClient::AuthCookie.new(cookies)
    if cookie.valid? && cookie.fresh?
      authenticate_with(cookie.token)
    end
  end

  # Auth is always remote, so that single sign-out works too.
  # Note this returns user if found, false if none, allowing authenticate_user to try something else.
  #
  def authenticate_with(combined_token)
    User.authenticate(combined_token)
  end

  def current_user
    RequestStore.store[:current_user]
  end

  def user_signed_in?
    !!current_user
  end
  
  def sign_in(user)
    RequestStore.store[:current_user] = user
  end
  
  def sign_in_and_remember(user)
    sign_in(user)
    set_auth_cookie_for(user)
  end

  def sign_out
    RequestStore.store[:current_user] = nil
    unset_auth_cookie
  end


  ## Domain cookies
  # are used to provide simple SSO support. A shared secret is required to decode the cookie,
  # and then authentication is checked against the data room server.
  #
  # Cookie holds encoded array of [uid, auth_token]
  #
  def set_auth_cookie_for(user)
    DroomClient::AuthCookie.new(cookies).set(user)
  end

  def unset_auth_cookie
    DroomClient::AuthCookie.new(cookies).unset
  end



  protected

  # A before_filter call to `assert_local_request!` will raise an error unless the request has
  # come in from the local subnet (which is usually a docker / ECS private network)
  #
  # We only do this on the controllers that deliver sensitive information. Country and
  # institution lists are available to all, with CORS settings that permit ajax access.
  #
  def assert_local_request!
    raise CanCan::AccessDenied unless local_request?
  end

  # Unlike the data room we default to permissive: in production you _must_ define a local subnet to secure the API.
  #
  def local_request?
    if local_subnet_defined?
      permitted_ip_range = IPAddr.new(ENV['LOCAL_SUBNET'] || Settings.api.local_subnet)
      permitted_ip_range === IPAddr.new(request.ip)
    else
      true
    end
  end

  def local_subnet_defined?
    ENV['LOCAL_SUBNET'].present? || Settings['api'].present? && Settings['api']['local_subnet'].present?
  end

  def pjax?
    !!request.headers['X-PJAX']
  end

  def signup_permitted?
    false
  end

end