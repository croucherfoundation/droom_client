class PasswordsController < ApplicationController
  include DroomAuthentication
  respond_to :json
  skip_before_action :authenticate_user!, raise: false

  def create
    @user = User.reset_password_request(password_params)
    if @user
      render json: {message: 'Password reset request sent'}
    else
      render json: {message: 'Password reset request failed'}, status: 302
    end
    
  end



  protected

  def password_params
    if params[:user]
      params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
    else
      {}
    end
  end


end
