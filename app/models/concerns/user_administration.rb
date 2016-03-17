# Include this concern to give your class a mechanism for invitation and acceptance
# that will do the right thing with data room users new and old.

module UserAdministration
  extend ActiveSupport::Concern

  included do
    attr_accessor :newly_accepted, :send_invitation, :send_reminder

    scope :accepted, -> {
      where("accepted_at IS NOT NULL")
    }

    scope :unaccepted, -> {
      where("accepted_at IS NULL")
    }

    scope :invited, -> {
      where("invited_at IS NOT NULL")
    }

    scope :uninvited, -> {
      where("invited_at IS NULL")
    }

    scope :reminded, -> {
      where("reminded_at IS NOT NULL")
    }

    scope :unreminded, -> {
      where("reminded_at IS NULL")
    }
    
    scope :invitable, -> {
      where("user_uid IS NOT NULL")
    }

    scope :uninvitable, -> {
      where("user_uid IS NULL")
    }
  end

  def status
    invited? ? accepted? ? "accepted" : "invited" : "uninvited"
  end

  def invitable?
    email?
  end

  def invited?
    invited_at?
  end

  def uninvited?
    !invited?
  end
  
  def reminded?
    reminded_at?
  end

  def unreminded?
    !reminded?
  end

  def accepted?
    accepted_at?
  end

  def unaccepted?
    !accepted?
  end
  
  # Note that this usually makes redundant the user-confirmation message that would be sent out by
  # the data room. Defer_confirmation should have been set on the newly-created user to prevent
  # the standard data room invitation also being sent out, and the acceptance method should always
  # take in a password-setting confirmation step.
  #
  def invite!
    if send_email('invitation')
      self.update_column :invited_at, Time.zone.now if respond_to?(:invited_at)
    end
  end
  
  def remind!
    if send_email('reminder')
      self.update_column(:reminded_at, Time.zone.now) if respond_to?(:reminded_at)
    end
  end

  def send_email(message='invitation')
    if Settings.mailer && defined? Settings.mailer.constantize
      mailer = Settings.mailer.constantize
      if mailer.respond_to? "#{message}_to_#{self.class.to_s.underscore}".to_sym
        ensure_invitation_token
        message = mailer.send("#{message}_to_#{self.class.to_s.underscore}".to_sym, self)
        message.deliver
      end
    end
  end
  
  def accept!
    unless accepted?
      self.update_column :accepted_at, Time.zone.now
    end
  end

  def newly_accepted?
    accepted? && accepted_at > 1.hour.ago
  end
  
  private
  
  def invite_if_inviting
    self.invite! if inviting?
  end

  def inviting?
    send_invitation && (send_invitation.to_s != "0") && (send_invitation.to_s != "false") && !accepted?
  end

  def remind_if_reminding
    self.remind! if reminding?
  end
  
  def reminding?
    send_reminder && (send_reminder.to_s != "0") && (send_reminder.to_s != "false") && invited? && !accepted?
  end

  def ensure_invitation_token
    if respond_to? :invitation_token
      while !self.invitation_token?
        token = generate_token
        self.update_column(:invitation_token, token) unless self.class.find_by(invitation_token: token)
      end
    end
  end

  def generate_token(length=12)
    SecureRandom.hex(length)
  end

end