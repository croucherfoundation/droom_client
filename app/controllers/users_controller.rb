class UsersController < ApplicationController
  include DroomAuthentication
  respond_to :html, :json
  before_filter :require_authenticated_user, only: [:index, :show, :edit, :update]
  before_filter :get_users, only: [:index]
  before_filter :get_user, only: [:show, :edit, :update, :confirm, :welcome]
  layout :no_layout_if_pjax

  # User-creation is always nested. 
  # Our usual purpose here is to list suggestions for the administrator choosing interviewers or screening judges
  #
  def index
    respond_with @users.to_a
  end
  
  # But people can change basic settings
  #
  def edit
    respond_with @user
  end
  
  def update
    authorize! :update, @user
    @user.assign_attributes(user_params)
    @user.save
    respond_with @user, location: droom_client.user_url(@user)
  end
  
  ## Confirmation
  #
  # This is the destination of the password-setting form that appears if a user accepts a role invitation
  # and has not yet set a password. A destination should have been provided by the acceptance view when the
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
  
  ## Suggestion
  #
  # This is to support the user-picker widget.
  # params: name fragment or email fragment.
  # response: json list of form values and user uids.
  #
  def suggest
    Rails.logger.warn "???  suggest! #{params[:email]}"
    limit = params[:limit].presence || 10
    if params[:email].present?
      @users = User.where(email_q: params[:email], limit: limit)
    elsif params[:name].present?
      @users = User.where(name_q: params[:name], limit: limit)
    end
    render json: @users.to_a
  end
  
protected

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
    params.require(:user).permit(:email, :password, :password_confirmation, :confirmed)
  end

end

