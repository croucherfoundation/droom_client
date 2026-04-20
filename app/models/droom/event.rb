class Droom::Event
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/events"
  root_element :event
  include_root_in_json true
  parse_root_in_json false
  request_new_object_on_build true

  after_create :assign_to_associates

  attr_accessor :associates

  def associates
    @associates ||= []
  end

  def self.new_with_defaults(attributes={})
    Droom::Event.new({
      name: "",
      description: nil,
      start: nil,
      finish: nil,
      end_date: nil
    }.merge(attributes))
  end

  def self.update_by_uuid(uuid, params = {})
    put "/api/events/#{uuid}", params
  end

  def self.destroy_by_uuid(uuid)
    delete "/api/events/#{uuid}"
    true
  end

  # Invite a Droom user to this event.
  # Returns the created Invitation.
  def invite_user(user_id)
    Invitation.create(event_id: id, user_id: user_id)
  end

  # Remove a user's invitation from this event.
  def uninvite(invitation_id)
    Invitation.destroy(event_id: id, id: invitation_id)
  end

protected

  def assign_to_associates
    associates.each do |ass|
      ass.event = self
    end
  end

end