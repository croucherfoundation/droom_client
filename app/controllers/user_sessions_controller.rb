class UserSessionsController < ApplicationController
  include DroomAuthentication
  before_action :require_no_user!, only: [:new, :create]
  before_action :authenticate_user!, only: [:destroy]
  skip_before_action :verify_authenticity_token, only: [:destroy], raise: false

  def new
    render
  end

  def create
    if user = User.sign_in(sign_in_params.to_h)
      if user.confirmed?
        RequestStore.store[:current_user] = user
        set_auth_cookie_for(user)
      else
        RequestStore.store.delete :current_user
        unset_auth_cookie
        reset_session
        redirect_to_url = "#{request.referrer.presence || droom_client.sign_in_path}?not_confirmed=true"
        redirect_to redirect_to_url and return
      end
      unless request.xhr?
        flash[:notice] = t("flash.greeting", name: user.given_name).html_safe
      end
      destination = params[:destination]
      if destination.present? && destination =~ /^\//
        redirect_to params[:destination]
      elsif destination.present? && params[:begin_application]
        redirect_to destination
      else
          redirect_to after_sign_in_path_for(user)
      end
    else
      # flash[:error] = t("flash.not_recognised").html_safe
      redirect_to_url = droom_client.sign_in_path
      sso = params[:sso]
      sig = params[:sig]

      if params[:destination].present? && params[:begin_application]
        redirect_to_url = "#{redirect_to_url}?destination=#{params[:destination]}&begin_application=true"
      elsif sso.present? && sig.present?
        redirect_to_url = "#{redirect_to_url}?sso=#{sso}&sig=#{sig}"
      else
        redirect_to_url = "#{request.referrer.presence || redirect_to_url}?failed=true"
      end

      redirect_to redirect_to_url
    end
  end

  def destroy
    current_user.sign_out!
    name = current_user.given_name
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
