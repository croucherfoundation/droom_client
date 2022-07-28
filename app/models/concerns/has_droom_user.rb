# The purpose of this module is to make it easy to associate a droom user to a local object.
# It often happens that...
#
# Since the user is a remote resource, this association only partly resembles a normal activerecord association.
#
# Requirements: user_uid column.
#
module HasDroomUser
  extend ActiveSupport::Concern

  included do
    scope :by_user, -> user_or_uid {
      uid = user_or_uid.respond_to?(:uid) ? user_or_uid.uid : user_or_uid
      where(user_uid: uid)
    }
  end

  ## Get
  #
  # Users are associated by uid in the hope of database and device independence. All we do here is go and get the user.
  #
  def user
    begin
      if user_uid?
        @_user ||= User.find(user_uid)
      end
      if respond_to?(:email?) && email?
        @_user ||= User.where(email: email).first
      end
    rescue => e
      Rails.logger.warn "#{self.class} #{self.id} has a user_uid that corresponds to no known data room user. Perhaps someone has been deleted? Ignoring. Error: #{e}"
      nil
    end
    @_user
  end

  def find_or_create_user
    unless user
      @_user = User.create({
        given_name: given_name,
        family_name: family_name,
        chinese_name: chinese_name,
        email: email
      })
      self.user_uid = @_user.uid
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
  # We only complete the save if nothing else is going on: if this record is new or has other changes,
  # we assume that this is part of a larger save operation.
  #
  def user=(user)
    also_save = self.persisted? && !self.changed?
    self.user_uid = user.uid
    @_user = user
    self.save if also_save
  end

  # Nil or value is meaningful. Empty string means that no value was set.
  def user_uid=(uid="")
    if uid != ""
      write_attribute(:user_uid, uid)
    end
  end

  # ### Nested creation of a new user
  #
  # +user_attributes=+ is only usually called during the nested creation of a new user object but it
  # is also possible for people to update some of their account settings through a remote service.
  #
  def user_attributes=(attributes)
    if attributes.any?
      if user = self.user
        user.assign_attributes(attributes.with_indifferent_access)
        user.save
      else
        attributes.reverse_merge!(defer_confirmation: confirmation_usually_deferred?)
        user = User.new_with_defaults(attributes)
        user.save
        self.user = user
      end
    end
  end

  # We sometimes keep a local version of some values that really belong to the user,
  # so as to speed up the display of lists or handle the case where no user exists.
  # This happens eg. when third parties are being added to a course lecturer list
  # who might later have to log in and contribute to the course.
  #
  # More central user-havers like the Person in core data will ensure that they
  # always have a user, even if it is not active, and delegate to that user.
  #
  def synchronise_with_user
    if user
      [:title, :given_name, :family_name, :chinese_name, :email, :emai, :preferred_professional_name, :preferred_pronoun].each do |col|
        if has_attribute?(col)
          if send("#{col}_changed?")
            user.send "#{col}=".to_sym, send(col)
          elsif user.send(col) != send(col)
            send "#{col}=".to_sym, user.send(col)
          end
        end
      end
      user.save if user.changed?
    else
      user = User.new_with_defaults({
        title: title,
        given_name: given_name,
        family_name: family_name,
        chinese_name: chinese_name,
        email: email,
        defer_confirmation: confirmation_usually_deferred?,
        preferred_professional_name: preferred_professional_name,
        preferred_pronoun: preferred_pronoun
      })
      user.save
      self.user = user
    end
  end

  # In the case of very thin local user-linking models like the Screener or Interviewer in the
  # application system, we can avoid a lot of API work by keeping a local copy of name,
  # email and other values that tend to appear in lists. Names are pulled from the remote
  # service, not pushed from the data room so we can't guarantee that they are up to date.
  #
  def cache_user_attributes
    if user
      [:name, :email].each do |col|
        if has_attribute?(col) && read_attribute(col) != user.send(col)
          write_attribute col, user.send(col)
        end
      end
    end
  end

  def ensure_user
    unless user?
      if user = find_or_create_user
        self.update_column :user_uid, user.uid
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

  def name
    read_attribute(:name).presence || user_name
  end

  def user_name
    user.name if user?
  end

  def formal_name
    user.formal_name if user?
  end

  def informal_name
    user.informal_name if user?
  end

  def colloquial_name
    user.colloquial_name if user?
  end

  def title_if_it_matters
    user.title_if_it_matters if user?
  end

  def icon
    user.icon if user?
  end

  def email
    read_attribute(:email).presence || user_email
  end

  def user_email
    user.email if user?
  end

end
