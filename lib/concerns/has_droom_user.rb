# The purpose of this module is to make it easy to associate a droom user to a local object.
# It often happens that 

module HasDroomUser
  extend ActiveSupport::Concern

  included do
    scope :by_user, -> uid {
      where(user_uid: uid)
    }
  end

  ## Get
  #
  # Users are associated by uid in the hope of database and device independence. All we do here is go and get the user.
  #
  def user
    begin
      if user_uid
        User.find(user_uid)
      end
    rescue => e
      Rails.logger.warn "#{self.class} #{self.id} has a user_uid that corresponds to no known data room user. Perhaps someone has been deleted? Ignoring."
      nil
    end
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
  end

  # ### Nested creation of a new user
  #
  # +user_attributes=+ is only usually called during the nested creation of a new user object but it
  # is also possible for people to update some of their account settings through a remote service.
  #
  def user_attributes=(attributes)
    if attributes.any?
      if self.user?
        self.user.assign_attributes(attributes)
        self.user.save
      else
        user = User.new_with_defaults
        user.assign_attributes(attributes)
        user.save
        self.user = user
      end
    end
  end

  def user?
    user_uid? && user
  end
  
  def confirmed?
    !!user.confirmed if user?
  end
  
  def send_confirmation_message!
    user.send_confirmation_message! if user?
  end

  def status
    invited? ? accepted? ? "accepted" : "invited" : "uninvited"
  end
  
  def name
    user.name if user?
  end

  def formal_name
    user.formal_name if user?
  end

  def colloquial_name
    user.colloquial_name if user?
  end

  def icon
    user.icon if user?
  end

  def email
    read_attribute(:email) || user_email
  end
  
  def user_email
    user.email if user?
  end
    
end