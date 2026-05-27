class User
  include Her::JsonApi::Model
  include ActiveSupport::Callbacks
  include HkNames

  define_callbacks :password_set
  attr_accessor :defer_confirmation

  use_api DROOM
  collection_path "/api/users"
  primary_key :uid
  root_element :user

  # temporary while we are not yet sending jsonapi data back to core properly
  include_root_in_json true
  parse_root_in_json false

  # login is a collection post
  # custom_post :sign_in

  def new?
    !respond_to?(:uid) || uid.nil?
  end

  def associates
    @associates ||= []
  end

  def associates=(these)
    @associates = these
  end

  def as_json(options={})
    {
      uid: uid,
      title: title,
      name: name,
      given_name: given_name,
      family_name: family_name,
      chinese_name: chinese_name,
      email: email,
      phone: phone,
      mobile: mobile,
      address: address,
      correspondence_address: try(:correspondence_address)
    }
  end

  def email_name
    given_name || family_name
  end

  def self.new_with_defaults(atts={})
    attributes = {
      uid: nil,
      unique_session_id: nil,
      title: "",
      given_name: "",
      family_name: "",
      chinese_name: "",
      affiliation: "",
      email: nil,
      phone: nil,
      mobile: nil,
      address: nil,
      correspondence_address: nil,
      password: nil,
      password_confirmation: nil,
      permission_codes: "",
      remember_me: false,
      confirmed: false,
      defer_confirmation: true,
      status: "",
      preferred_pronoun: "",
      preferred_professional_name: "",
      preferred_name: "",
      image: nil,
    }.with_indifferent_access.merge(atts)
    self.new(attributes)
  end

  def self.accounts(group_ids: [], user_uids: [])
    get "/api/users/accounts", {group_ids: group_ids, user_uids: user_uids}
  rescue => e
    Rails.logger.error "[droom_client] Error getting group users: #{e.message}"
    nil
  end

  ## Retrieval
  #
  # User#find returns a user data object suitable for management or display but without auth information.
  # The other calls below return a smaller user object with only the auth information needed for greeting and session creation.
  #
  # Present token (usually from auth_cookie), get user object back with authentication attributes.
  #
  def validate_email?
    response = self.class.get "/api/users/#{self.uid}/validate_email"
    valid = response&.persisted? && response&.metadata&.[](:valid)
    !!valid
  rescue JSON::ParserError, Her::Errors::ParseError => e
    # Log the error for debugging purposes
    Rails.logger.error "[droom_client] Error parsing validation response for user #{uid}: #{e.message}"
    false
  rescue Faraday::Error => e # Catch potential network/connection errors
    Rails.logger.error "[droom_client] Network error validating email for user #{uid}: #{e.message}"
    false
  rescue StandardError => e # Catch other unexpected errors
    Rails.logger.error "[droom_client] Unexpected error validating email for user #{uid}: #{e.class} - #{e.message}"
    false
  end

  def self.authenticate(token)
    user = get "/api/authenticate/#{token}"
    if user && user.persisted?
      user
    else
      nil
    end
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def sign_out!
    self.class.get "/api/deauthenticate/#{unique_session_id}"
  end

  # Present email and password (usually from login form), get user object back with authentication attributes.
  #
  def self.sign_in(params)
    user = post "/api/users/sign_in", params
    if user.id
      user
    else
      nil
    end
  rescue => e
    Rails.logger.warn "[droom_client] sign in fail: #{e.message}"
    nil
  end

  # Present user id (usually from an association, eg upon accepting invitation), get user object back with authentication attributes.
  #
  def self.for_authentication(uid)
    user = get "/api/users/authenticable/#{uid}"
  end

  def send_confirmation_message!
    self.assign_attributes send_confirmation: true
    self.save
  end

  def self.send_otp(uid)
    user = get "/api/users/#{uid}/send_otp"
  end

  def self.verify_otp(uid, params)
    params = params.to_h unless params == {}
    post "/api/users/#{uid}/verify_otp", params
  end

  def self.reindex_user(user_uid)
    begin
      post "/api/users/#{user_uid}/reindex"
    rescue JSON::ParserError, Her::Errors::ParseError
      nil
    end
  end

  def confirm!
    self.confirmed = true
    self.save
  end

  def update_last_request_at!
    self.last_request_at=Time.now
    self.save
  end

  def self.update_contacts(user_uid, params={})
    params = params.to_h unless params == {}
    put "/api/users/#{user_uid}/update_contact", params
  end


  def self.account_update(user_uid, params={})
    params = params.to_h unless params == {}
    put "/api/users/#{user_uid}/account_update", params
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def self.check_valid_password(user_uid, password)
    response = DROOM.connection.post("/api/users/#{user_uid}/check_valid_password") do |req|
      req.body = { user: { current_password: password } }.to_json
      req.headers['Content-Type'] = 'application/json'
    end
    response.status == 200
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.error "[droom_client] check_valid_password error: #{e.message}"
    false
  end

  def self.account_setting_update(user_uid, params={})
    params = params.to_h unless params == {}
    put "/api/users/#{user_uid}/account_setting_update", params
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def self.verify_email(token)
    params = { token: token }
    get "/api/users/verify_email", params
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def self.sync_profile_image(user_uid, params={})
    params = params.to_h unless params == {}
    get "/api/users/#{user_uid}/sync_profile_image", params
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def remove_profile(user_uid)
    self.class.get "/api/users/#{user_uid}/remove_profile"
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def upload_profile_image(user_uid, base64_image)
    self.class.put "/api/users/#{user_uid}/upload_profile_image", image: base64_image
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def remove_reviewer_group(user_uid)
    self.class.delete "/api/users/#{user_uid}/remove_reviewer_group"
  end

  def self.sign_up(params)
    params = params.to_h unless params == {}
    user = post "/api/users/sign_up", params
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def self.reset_password_request(params)
    params = params.to_h unless params == {}
    user = post "/api/users/passwords", params
  rescue JSON::ParserError, Her::Errors::ParseError
    nil
  end

  def unconfirmed?
    !self.confirmed?
  end

  def set_password!(user_params)
    run_callbacks :password_set do
      assign_attributes(user_params.to_h)
      assign_attributes(confirmed: true)
      save
    end
  end

  def to_param
    uid
  end

  def permitted?(key)
    permission_codes.include?(key)
  end

  def permit!(code)
    #TODO
    #permission_codes << code unless permission_codes.include?(code)
    #save
  end

  def allowed_here?
    permitted?("#{Settings.service_name}.login")
  end

  def permit_here
    permit!("#{Settings.service_name}.login")
  end

  def admin?
    sysadmin? || permitted?("#{Settings.service_name}.admin")
  end

  def csw_admin?
    permitted?("csw.login")
  end

  def csw_helper?
    permitted?("csw.helper")
  end

  def sysadmin?
    status == "admin"
  end

  def senior?
    sysadmin? || status == "senior"
  end

  def internal?
    senior? || status == "internal"
  end

  def external?
    !internal?
  end

  def image
    self.images ||= {}
    images[:standard]
  end

  def icon
    self.images ||= {}
    images[:icon]
  end

  def thumbnail
    self.images ||= {}
    images[:thumbnail]
  end

  def best_address
    correspondence_address.presence || address
  end

  def needs_setup?
    user = self.class.get("/api/users/#{uid}")
    user.needs_setup
  end

end
