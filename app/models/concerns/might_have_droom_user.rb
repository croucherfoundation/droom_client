module MightHaveDroomUser
  extend ActiveSupport::Concern
  include HkNames

  included do
    scope :by_user, -> uid {
      uid = uid.uid if uid.respond_to? :uid
      where(user_uid: uid)
    }
  end

  ## Get
  #
  # Users are associated by uid in the hope of database and device independence. All we do here is go and get the user.
  #
  def user
    unless @user
      begin
        if user_uid.present?
          @user = User.find(user_uid)
        end
      rescue => e
        Rails.logger.warn "#{self.class} #{self.id} has a user_uid that does not give us a data room user. Perhaps someone has been deleted? Ignoring."
        nil
      end
    end
    @user
  end

  def find_or_create_user
    unless user
      if email
        @_user = User.create({
          given_name: given_name,
          family_name: family_name,
          chinese_name: chinese_name,
          email: email
        })
        self.user_uid = @_user.uid
      end
    end
    @_user
  end

  ## Set
  #
  # Users are assigned in two ways: by direct association to an existing user object, or by the inline creation of a new
  # user object during the creation of a local object.
  #
  # ### Assigning an existing user
  #
  # +user=+ will be called in two situations: during a compound save with an existing user object, 
  # or immediately upon the creeation of a new user, on the object that it was created with.
  # We only save ourselves if nothing else is going on: if this record is new or has other changes,
  # we assume that this is part of a larger save operation.
  #
  def user=(user)
    also_save = self.persisted? && !self.changed?
    self.user_uid = user.uid
    self.save if also_save
    @user = user
  end

  # ### Nested creation of a new user
  #
  # +user_attributes=+ is only usually called during the nested creation of a new user object but it
  # is also possible for people to update some of their account settings through a remote service.
  #
  def user_attributes=(attributes)
    if attributes.any?
      if user = self.user
        user.update_attributes(attributes.with_indifferent_access)
        user.save
      else
        attributes.reverse_merge!(defer_confirmation: confirmation_usually_deferred?)
        user = User.new_with_defaults(attributes)
        user.save
        self.user = user
      end
    end
  end
  
  def confirmation_usually_deferred?
    true
  end

  def user?
    user_uid? && user.present?
  end
  
  def confirmed?
    !!user.confirmed if user?
  end
  
  # unlike hasDroomUser, we interfere with the name parts to provide either
  # user properties or local attributes.
  
  def title
    if user? then user.title else read_attribute(:title) end
  end
  
  def family_name
    if user? then user.family_name else read_attribute(:family_name) end
  end

  def given_name
    if user? then user.given_name else read_attribute(:given_name) end
  end

  def email
    if user? then user.email else read_attribute(:email) end
  end
  
  def icon
    user.icon if user?
  end

  def informal_name
    if user? then user.informal_name else [given_name, family_name].join(' ') end
  end

  def colloquial_name
    if user? then user.colloquial_name else [title, given_name, family_name].join(' ') end
  end
    
end