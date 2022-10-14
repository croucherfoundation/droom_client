class Api::SessionsController < ApplicationController
  # include Droom::Concerns::LocalApi
  protect_from_forgery except: :sign_in
  respond_to :json
  # skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  def new
    render
  end

  def create
    if user = User.sign_in(sign_in_params.to_h)
      RequestStore.store[:current_user] = user
      set_auth_cookie_for(user)
      cookie_name = ENV['DROOM_AUTH_COOKIE'] || Settings.auth.cookie_name
      user = {unique_session_id: user.unique_session_id, "#{cookie_name}": JSON.parse(cookies[:_croucher_dev_auth])}
      render :json => user
    else
      error_msg = {:error_message => "Sign in error!"}
      render :json => error_msg
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
