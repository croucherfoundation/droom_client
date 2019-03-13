class UserSessionsController < ApplicationController
  include DroomAuthentication
  before_action :require_no_user!, only: [:new, :create]
  before_action :authenticate_user!, only: [:destroy]

  def new
    Rails.logger.warn "Session new: #{sign_in_params.inspect}"
    render
  end

  def create
    Rails.logger.warn "Session create: #{sign_in_params.inspect}"
    if user = User.sign_in(sign_in_params.to_h)
      RequestStore.store[:current_user] = user
      set_auth_cookie_for(user, Settings.auth.cookie_domain, params[:user][:remember_me])
      unless request.xhr?
        flash[:notice] = t("flash.greeting", name: user.formal_name).html_safe
      end
      if params[:destination].present?
        redirect_to params[:destination]
      else
        redirect_to after_sign_in_path_for(user)
      end
    else
      redirect_to droom_client.sign_in_path
    end
  end

  def destroy
    current_user.sign_out!
    name = current_user.formal_name
    RequestStore.store.delete :current_user
    unset_auth_cookie(Settings.auth.cookie_domain)
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
