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
      email: email,
      phone: phone
    }
  end

  def self.new_with_defaults(attributes={})
    attributes = {
      uid: nil,
      title: "",
      given_name: "",
      family_name: "",
      chinese_name: "",
      affiliation: "",
      email: "",
      phone: "",
      password: "",
      password_confirmation: "",
      permission_codes: "",
      remember_me: false,
      confirmed: false,
      person_uid: nil,
      defer_confirmation: true
    }.with_indifferent_access.merge(attributes)
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

  def send_confirmation_message!
    self.assign_attributes send_confirmation: true
    self.save
  end
  
  def sign_out!
    self.class.get "/api/deauthenticate/#{authentication_token}"
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
    permitted?("#{Settings.service_name}.admin")
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
