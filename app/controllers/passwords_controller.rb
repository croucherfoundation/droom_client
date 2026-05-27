class PasswordsController < ApplicationController
  include DroomAuthentication
  respond_to :json
  skip_before_action :authenticate_user!, raise: false
  before_action :set_email

  def create
    error_message = I18n.t(:password_reset_not_delivered)

    unless @email_record&.can_receive_email?
      return render json: { error: error_message }, status: :bad_request
    end

    @user = User.reset_password_request(reset_password_request_params)
    if @user
      render json: { message: 'Password reset request sent' }
    else
      render json: { error: error_message }, status: :bad_request
    end
  end

  protected

  def set_email
    @email_record = Email.where(email: reset_password_request_params[:email]).first
  end

  def password_params
    if params[:user]
      params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
    else
      {}
    end
  end

  def reset_password_request_params
    password_params.slice(:email).merge(destination: reset_password_destination)
  end

  def reset_password_destination
    params[:destination].presence ||
      params[:backto].presence ||
      params.dig(:user, :destination).presence ||
      params.dig(:user, :backto).presence
  end


end
