class UsersController < ApplicationController
  include DroomAuthentication

  respond_to :html, :json

  skip_before_action :authenticate_user!, raise: false
  before_action :require_authenticated_user, only: [:index, :show, :edit, :update, :suggest]
  before_action :get_users, only: [:index]
  before_action :get_user, only: [:show, :edit, :update, :confirm, :welcome]
  before_action :get_view, only: [:edit]
  layout :no_layout_if_pjax


  def create
    @user = User.new_with_defaults(user_params)
    if @user.save
      sign_in_and_remember @user
      if params[:destination].present?
        redirect_to params[:destination]
      else
        respond_with @user
      end
    else
      
    end
  end


  # Our usual purpose here is to list suggestions for the administrator choosing interviewers or screening judges
  #
  def index
    respond_with @users.to_a
  end


  # But users can change account settings and contact information
  #

  def update
    authorize! :update, @user
    @user.assign_attributes(user_params)
    @user.save
    respond_with @user, location: droom_client.user_url(@user)
  end


  ## Confirmation
  #
  # This is the destination of the password-setting form that appears if a user accepts a role invitation
  # and has not yet set a password. A final destination should have been provided by the acceptance view when the
  # confirmation form was included.
  #
  def set_password
    if @user = User.authenticate(params[:tok])
      sign_in_and_remember @user
      @user.set_password!(user_params)
      flash[:notice] = t(:password_set)
      respond_with @user, location: params[:destination].present? ? params[:destination] : after_sign_in_path_for(@user)
    else
      raise ActiveRecord::RecordNotFound, "Sorry: User credentials not recognised."
    end
  end


  ## Account checking
  #

  def check_email
    in_use = params[:email].present? && User.where(email: params[:email]).any?
    message = 'whoops'
    if in_use
      message = 'oops'
    end
    render json: {message: message}
  end


  ## Suggestion
  #
  # This is to support the user-picker widget.
  # params: name fragment or email fragment.
  # response: json list of form values and user uids.
  #
  def suggest
    authorize! :manage, User
    limit = params[:limit].presence || 10
    if params[:email].present?
      @users = User.where(email_q: params[:email], limit: limit)
    elsif params[:name].present?
      @users = User.where(name_q: params[:name], limit: limit)
    end
    render json: @users.to_a
  end

  def check_authenticate
    if current_user.present?
      render json: { email: current_user['email'], name: current_user['name']}, status: :ok
    else
      render json: { errors: "Token not recognised" }, status: :unauthorized
    end
  end


protected

  def get_view
    @view = params[:view] if permitted_views.include?(params[:view])
    @view ||= default_view
  end

  def permitted_views
    %w{account contacts}
  end

  def default_view
    'account'
  end

  def get_user
    if params[:id].present? && can?(:manage, User)
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

  def get_users
    if can?(:manage, User)
      @users = User.all
      @show = params[:show] || 10
      @page = params[:page] || 1
      unless @show == 'all'
        @users = @users.page(@page).per(@show)
      end
      @users
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :title, :family_name, :given_name, :chinese_name, :affiliation, :confirmed, :email, :phone, :mobile, :address, :correspondence_address)
  end

end

