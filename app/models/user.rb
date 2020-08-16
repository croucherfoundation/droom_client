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
      correspondence_address: correspondence_address
    }
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
      status: ''
    }.with_indifferent_access.merge(atts)
    self.new(attributes)
  end

  ## Retrieval
  #
  # User#find returns a user data object suitable for management or display but without auth information.
  # The other calls below return a smaller user object with only the auth information needed for greeting and session creation.
  #
  # Present token (usually from auth_cookie), get user object back with authentication attributes.
  #
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

end
