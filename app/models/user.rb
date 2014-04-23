class User
  include HkNames
  include PaginatedHer::Model

  use_api DROOM
  primary_key :uid
  collection_path "/api/users"
  root_element :user

  after_save :decache

  attr_accessor :defer_confirmation

  def new?
    !respond_to?(:uid) || uid.nil?
  end

  def associates
    @associates ||= []
  end

  def associates=(these)
    @associates = these
  end

  def self.new_with_defaults(attributes={})
    self.new({
      uid: nil,
      title: "",
      given_name: "",
      family_name: "",
      chinese_name: "",
      email: "",
      phone: "",
      password: "",
      permission_codes: "",
      remember_me: false,
      confirmed: false,
      defer_confirmation: false,
      image: nil
    }.merge(attributes))
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
    images[:standard]
  end
  
  def icon
    images[:icon]
  end

  def thumbnail
    images[:thumbnail]
  end

  protected
  
  def decache
    $cache.flush_all if $cache
  end

end
