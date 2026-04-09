class Invitation
  include Her::JsonApi::Model

  use_api DROOM
  root_element :invitation
  request_new_object_on_build true

  def self.collection_path(event_id = nil)
    "/api/events/#{event_id}/invitations"
  end

  # Her doesn't natively support nested routes, so we override save/destroy
  # to target /api/events/:event_id/invitations.

  attr_accessor :event_id

  def save
    raise ArgumentError, "event_id is required" unless event_id.present?
    params = { invitation: { user_id: user_id } }
    response = DROOM.connection.post("/api/events/#{event_id}/invitations", params)
    parsed = JSON.parse(response.body)
    if parsed["invitation"]
      assign_attributes(parsed["invitation"])
    end
    self
  end

  def destroy
    raise ArgumentError, "event_id is required" unless event_id.present?
    DROOM.connection.delete("/api/events/#{event_id}/invitations/#{id}")
    self
  end

  def self.create(attributes = {})
    event_id = attributes.delete(:event_id) || attributes.delete("event_id")
    invitation = new(attributes)
    invitation.event_id = event_id
    invitation.save
  end

  def self.destroy(event_id:, id:)
    DROOM.connection.delete("/api/events/#{event_id}/invitations/#{id}")
  end
end
