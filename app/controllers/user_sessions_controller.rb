class UserSessionsController < ApplicationController
  include DroomAuthentication
  skip_before_ation :authenticate_user!
  before_action :require_no_user!, only: [:new, :create]
  before_action :authenticate_user!, only: [:destroy]

  def new
    render
  end

  def create
    if user = User.sign_in(sign_in_params)
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
    params.require(:user).permit(:email, :password, :remember_me)
  end
end
