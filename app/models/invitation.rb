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
    invitation = self.class.post "/api/events/#{event_id}/invitations", params
    assign_attributes(invitation.attributes) if invitation.respond_to?(:attributes)
    self.event_id = event_id
    self
  end

  def destroy
    raise ArgumentError, "event_id is required" unless event_id.present?

    self.class.delete "/api/events/#{event_id}/invitations/#{id}"
    self
  end

  def self.create(attributes = {})
    event_id = attributes.delete(:event_id) || attributes.delete("event_id")
    invitation = new(attributes)
    invitation.event_id = event_id
    invitation.save
  end

  def self.for_event(event_id)
    invitations = get "/api/events/#{event_id}/invitations"
  rescue => e
    Rails.logger.error "[droom_client] Error getting invitations: #{e.message}"
    []
  end

  def self.destroy(event_id:, id:)
    delete "/api/events/#{event_id}/invitations/#{id}"
  end
end
