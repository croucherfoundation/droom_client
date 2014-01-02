class UserSessionsController < ApplicationController
  skip_before_filter :authenticate_user
  before_filter :require_no_user!, only: [:new, :create]

  def new
    @user = User.new_with_defaults
    render
  end

  def create
    if user = User.post("/users/sign_in.json", params[:user])
      RequestStore.store[:current_user] = user
      set_auth_cookie_for(user, Settings.auth.cookie_domain, params[:user][:remember_me])
      flash[:notice] = t("flash.greeting", name: user.formal_name).html_safe
      redirect_to after_sign_in_path_for(user)
    else
      redirect_to new_user_session_path
    end
  end

  def destroy
    if @user = current_user
      @user.sign_out!
      RequestStore.store.delete :current_user
      flash[:notice] = t("flash.goodbye", name: @user.formal_name).html_safe
    end
    unset_auth_cookie(Settings.auth.cookie_domain)
    redirect_to after_sign_out_path_for(@user)
  end

end
