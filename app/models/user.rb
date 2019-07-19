class User
  include ActiveSupport::Callbacks
  include HkNames
  include Her::JsonApi::Model

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
      authentication_token: nil,
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

  def self.authenticate(token)
    begin
      get "/api/authenticate/#{token}"
    rescue JSON::ParserError
      nil
    end
  end

  def self.sign_in(params)
    begin
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
  end

  def send_confirmation_message!
    self.assign_attributes send_confirmation: true
    self.save
  end

  def sign_out!
    self.class.get "/api/deauthenticate/#{authentication_token}"
  end

  def self.reindex_user(user_uid)
    begin
      post "/api/users/#{user_uid}/reindex"
    rescue JSON::ParserError
      nil
    end
  end

  def confirm!
    self.confirmed = true
    self.save
  end

  def unconfirmed?
    !self.confirmed?
  end

  def set_password!(user_params)
    run_callbacks :password_set do
      assign_attributes(user_params)
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
