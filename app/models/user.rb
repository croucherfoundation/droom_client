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
      emails: emails,
      email: email,
      phones: phones,
      phone: phone,
      addresses: addresses
    }
  end

  def self.new_with_defaults(atts={})
    attributes = {
      uid: nil,
      title: "",
      given_name: "",
      family_name: "",
      chinese_name: "",
      affiliation: "",
      emails: [],
      phones: [],
      addresses: [],
      password: "",
      password_confirmation: "",
      permission_codes: "",
      remember_me: false,
      confirmed: false,
      defer_confirmation: true,
      status: ''
    }.with_indifferent_access.merge(atts)
    self.new(attributes)
  end

  def self.sign_in(params)
    self.post("/users/sign_in.json", params)
  end

  def self.authenticate(token)
    begin
      get "/api/authenticate/#{token}"
    rescue JSON::ParserError
      nil
    end
  end

  def email
    emails.first if emails
  end

  def phone
    phones.first if phones
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

  def unconfirmed_email?
    self.unconfirmed_email.present?
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

end
