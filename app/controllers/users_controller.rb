class UsersController < ApplicationController
  include DroomAuthentication

  respond_to :html, :json

  skip_before_action :authenticate_user!, raise: false
  before_action :require_authenticated_user, only: [:index, :show, :edit, :update, :suggest, :remove_profile, :upload_profile_image, :account_setting_update]
  before_action :get_users, only: [:index]
  before_action :get_user, only: [:show, :edit, :update, :confirm, :welcome, :remove_profile, :upload_profile_image, :account_setting_update]
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
    destination = referer_params['destination'].presence || root_url

    permitted_params = user_params.merge(
      ip_address: request.ip,
      browser_agent: request.user_agent,
      after_confirmed_url: destination
    )

    @user = User.sign_up(permitted_params)
    error_messages = @user&.metadata&.[](:error_message)

    @show_email_confirm_popup = true
    referer_url = request.referer
    uri = URI.parse(referer_url)
    referer_params = Rack::Utils.parse_query(uri.query || '')
    referer_params['show_email_confirm_popup'] = true
    uri.query = referer_params.to_query
    redirect_url = uri.to_s

    if error_messages.present?
      error_message = Array(error_messages).first.to_s

      if error_message.end_with?("Email address provided is invalid")
        error_message = "Email address provided is invalid"
      end

      render json: { error_message: error_message }, status: :unprocessable_entity
    else
      if request.xhr? || request.format.json?
        render json: { redirect_url: redirect_url }
      else
        redirect_to redirect_url
      end
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
    hashed_params = user_params
    hashed_params[:emails_attributes] = hashed_params[:emails_attributes]&.to_h
    hashed_params[:addresses_attributes] = hashed_params[:addresses_attributes]&.to_h
    # Validate image if present
    if hashed_params[:image].present?
      unless is_valid_image?(hashed_params[:image])
        error_message = "Image must be a valid image file (JPEG, PNG, GIF, etc.)"
        return render json: { error_message: error_message }, status: 422
      end
      hashed_params[:image] = convert_image_to_base64(hashed_params[:image].tempfile.path)
    end
    hashed_params[:remove_image] = true if params[:remove_image] == "true" ||  params[:remove_image] == true
    @user.assign_attributes(hashed_params.to_h)
    @user.save
    error_message = @user.metadata&.[](:error)
    if error_message.present?
      validate_email = error_message.is_a?(Array) ? error_message.include?("Email address provided is invalid") : (error_message == "Email address provided is invalid")
      render json: { error_message: error_message, validate_email: validate_email }, status: 422

    else
      respond_with @user, location: params[:reload] == "true" ? request.referer : droom_client.user_url(@user)
    end
  end

  def remove_profile
    result = @user.remove_profile(@user.uid)
    if result
      render json: { data: { attributes: { profile_image: result.try(:image) || result.try(:[], :image) } } }, status: :ok
    else
      render json: { error: 'Failed to remove profile image.' }, status: :unprocessable_entity
    end
  end

  def upload_profile_image
    base64_image = params[:user][:image]
    result = @user.upload_profile_image(@user.uid, base64_image)
    if result
      render json: { data: { attributes: { profile_image: result.try(:image) || result.try(:[], :image) } } }, status: :ok
    else
      render json: { error: 'Failed to upload profile image.' }, status: :unprocessable_entity
    end
  end

  def account_setting_update
    authorize! :update, @user
    return if password_change_invalid?(user_params)

    permitted = sanitized_account_params(user_params)

    result = User.account_setting_update(@user.uid, permitted)

    if result.present? && result.try(:uid).present?
      respond_to_successful_update(permitted)
    else
      error_msg = result.try(:metadata)&.[](:error) || "Failed to update account settings"
      render_update_error(error_msg)
    end
  rescue StandardError => e
    render_update_error("An unexpected error occurred.")
    Rails.logger.error("[AccountSettingUpdate] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
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
    message = 'whoops'
    if params[:email].present?
      users = User.where(email: params[:email])
      # Exclude current user's own email from the check
      if params[:user_id].present?
        users = users.reject { |u| u.id.to_s == params[:user_id].to_s }
      end
      message = 'oops' if users.any?
    end
    render json: { message: message }
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
    params.require(:user).permit(:email, :primary_email, :backup_email, :password, :password_confirmation, :current_password, :title, :family_name, :given_name, :chinese_name, :affiliation, :confirmed, :phone, :mobile, :address, :image, :correspondence_address, :timezone, :organisation_admin, :admin, :gatekeeper, emails_attributes: [:id, :email, :current_email, :address_type_id, :_destroy], addresses_attributes: [:id, :address, :address_type_id, :_destroy])
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

  def is_valid_image?(image)
    FileSecurityService.allowed_image?(image.content_type)
  end

  # Mirrors droom's password_change_invalid? logic
  def password_change_invalid?(params)
    current_password = params[:current_password]
    new_password = params[:password]

    return false if current_password.blank? && new_password.blank?

    if current_password.blank?
      return render_update_error("Current password is required to set a new password.")
    end

    unless User.check_valid_password(@user.uid, current_password)
      return render_update_error("Current password is incorrect.")
    end

    if new_password.blank?
      return render_update_error("New password cannot be blank.")
    end

    if new_password == current_password
      return render_update_error("New password must be different from current password.")
    end

    false
  end

  # Maps form fields to what droom's API account_setting_update expects
  def sanitized_account_params(params)
    account = {}
    account[:first_name] = params[:given_name] if params[:given_name].present?
    account[:last_name] = params[:family_name] if params[:family_name].present?
    account[:email] = params[:primary_email] if params[:primary_email].present?
    account[:backup_email] = params[:backup_email] if params.key?(:backup_email)
    account[:timezone] = params[:timezone] if params[:timezone].present?
    account[:current_password] = params[:current_password] if params[:current_password].present?
    account[:new_password] = params[:password] if params[:password].present?
    account
  end

  def render_update_error(message, status = :unprocessable_entity)
    if request.xhr?
      render json: { error_message: message }, status: status
    else
      flash[:alert] = message
      redirect_to request.referer
    end
    true
  end

  def respond_to_successful_update(permitted)
    if permitted[:email].present? && permitted[:email] != current_user.primary_email
      message = "Verification email sent to #{permitted[:email]}. Please check your inbox."
      if request.xhr?
        render json: { message: message, verification_required: true }, status: :ok
      else
        flash[:notice] = message
        redirect_to request.referer
      end
    else
      if request.xhr?
        render json: { message: "Account settings saved successfully." }, status: :ok
      else
        flash[:notice] = "Account settings saved successfully."
        redirect_to request.referer
      end
    end
  end

end
