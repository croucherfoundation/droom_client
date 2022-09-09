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
          redirect_to after_sign_in_path_for(user)
      end
    else
      flash[:error] = t("flash.not_recognised").html_safe
      redirect_to_url = droom_client.sign_in_path

      sso = params[:sso]
      sig = params[:sig]
      if sso.present? && sig.present?
        redirect_to_url = "#{redirect_to_url}?sso=#{sso}&sig=#{sig}"
      end

      redirect_to redirect_to_url
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
      params.require(:user).permit(:email, :password, :remember_me)
    else
      {}
    end
  end
end

