class UserSessionsController < ApplicationController
  include DroomAuthentication
  before_action :require_no_user!, only: [:new, :create]
  before_action :authenticate_user!, only: [:destroy]

  def new
    render
  end

  def create
    if user = User.sign_in(sign_in_params.to_h)
      RequestStore.store[:current_user] = user
      set_auth_cookie_for(user)
      unless request.xhr?
        flash[:notice] = t("flash.greeting", name: user.formal_name).html_safe
      end
      destination = params[:destination]
      if destination.present? && destination =~ /^\//
        redirect_to params[:destination]
      else
        sso = params[:sso]
        if sso.present?
          url = sso_url(user)
          redirect_to url
        else
          redirect_to after_sign_in_path_for(user)
        end
      end
    else
      flash[:error] = t("flash.not_recognised").html_safe
      redirect_to droom_client.sign_in_path
    end
  end

  def destroy
    current_user.sign_out!
    name = current_user.formal_name
    RequestStore.store.delete :current_user
    unset_auth_cookie
    reset_session
    if request.xhr?
      head :ok
    else
      flash[:notice] = t("flash.goodbye", name: name).html_safe
      redirect_to after_sign_out_path_for(current_user), method: "get"
    end
  end

  protected
  
  def sign_in_params
    if params[:user]
      params.require(:user).permit(:email, :password, :remember_me, :sso, :sig)
    else
      {}
    end
  end

  def get_sign(app_secret, payload)
    OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload)
  end

  def get_encode_to_urlencode(payload)
    CGI.escape payload
  end
end

