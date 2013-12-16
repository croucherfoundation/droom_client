class UserSessionsController < ApplicationController
  before_filter :require_no_user!, only: [:new, :create]
  
  def new
    @user = User.new(email: "", password: "", remember_me: false)
    render
  end
  
  def create
    if user = User.post(Settings.droom.auth_path, params[:user])
      RequestStore.store[:current_user] = user
      set_auth_cookie_for(user, Settings.auth.cookie_domain, params[:user][:remember_me])
      session[:current_user] = user
      flash[:notice] = t("flash.greeting", name: user.formal_name).html_safe
      redirect_to after_sign_in_path_for(user)
    else
      redirect_to new_user_session_path
    end
  end
  
  def destroy
    user = current_user
    unset_auth_cookie(Settings.auth.cookie_domain)
    session.delete :current_user
    RequestStore.store.delete :current_user
    flash[:notice] = t("flash.goodbye", name: user.formal_name).html_safe
    redirect_to after_sign_out_path_for(user)
  end
  
end
