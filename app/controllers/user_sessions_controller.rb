class UserSessionsController < ApplicationController
  include DroomAuthentication
  skip_before_filter :authenticate_user
  before_filter :require_no_user!, only: [:new, :create]
  before_filter :authenticate_user!, only: [:destroy]

  def new
    render
  end

  def create
    if user = User.sign_in(user: sign_in_params)
      RequestStore.store[:current_user] = user
      set_auth_cookie_for(user, Settings.auth.cookie_domain, params[:user][:remember_me])
      flash[:notice] = t("flash.greeting", name: user.formal_name).html_safe
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
    flash[:notice] = t("flash.goodbye", name: current_user.formal_name).html_safe
    RequestStore.store.delete :current_user
    unset_auth_cookie(Settings.auth.cookie_domain)
    reset_session
    redirect_to after_sign_out_path_for(current_user)
  end

  protected
  
  def sign_in_params
    params.require(:user).permit(:email, :password, :remember_me)
  end
end
