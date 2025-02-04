class UsersController < ApplicationController
  include DroomAuthentication

  respond_to :html, :json

  skip_before_action :authenticate_user!, raise: false
  before_action :require_authenticated_user, only: [:index, :show, :edit, :update, :suggest, :remove_profile]
  before_action :get_users, only: [:index]
  before_action :get_user, only: [:show, :edit, :update, :confirm, :welcome, :remove_profile]
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

  def sign_up
    referer_url = request.referer
    uri = URI.parse(referer_url)
    referer_params = Rack::Utils.parse_query(uri.query || '')
    destination = referer_params['destination'].present? ? referer_params['destination'] : root_url
    permitted_params = user_params.merge(ip_address: request.ip, browser_agent: request.user_agent, after_confirmed_url: destination)
    @user = User.sign_up(permitted_params)
    @show_email_confirm_popup = true
    referer_url = request.referer
    uri = URI.parse(referer_url)
    referer_params = Rack::Utils.parse_query(uri.query || '')
    referer_params['show_email_confirm_popup'] = true
    uri.query = referer_params.to_query

    redirect_to uri.to_s
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
    hashed_params = user_params
    hashed_params[:emails_attributes] = hashed_params[:emails_attributes]&.to_h
    hashed_params[:addresses_attributes] = hashed_params[:addresses_attributes]&.to_h
    hashed_params[:image] = convert_image_to_base64(hashed_params[:image].tempfile.path) if hashed_params[:image].present?
    hashed_params[:remove_image] = true if params[:remove_image] == "true" ||  params[:remove_image] == true
    @user.assign_attributes(hashed_params.to_h)
    @user.save
    respond_with @user, location: params[:reload] == "true" ? request.referer : droom_client.user_url(@user)
  end

  def remove_profile
    @user.remove_profile(@user.uid)
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
    params.require(:user).permit(:email, :password, :password_confirmation, :title, :family_name, :given_name, :chinese_name, :affiliation, :confirmed, :email, :phone, :mobile, :address, :image, :correspondence_address, :timezone, :organisation_admin, :admin, :gatekeeper, emails_attributes: [:id, :email, :current_email, :address_type_id, :_destroy], addresses_attributes: [:id, :address, :address_type_id, :_destroy])
  end

  def convert_image_to_base64(image_path)
    # Read the image file
    file = File.open(image_path, 'rb')
    image_data = file.read
  
    # Get MIME type (e.g., "image/png" or "image/jpeg")
    mime_type = Marcel::MimeType.for(image_path)
  
    # Encode to Base64
    base64_image = Base64.encode64(image_data)
  
    # Combine with MIME type
    "data:#{mime_type};base64,#{base64_image}"
  ensure
    # Close the file to free resources
    file.close if file
  end

end
