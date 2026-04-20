require File.dirname(__FILE__) + '/../spec_helper'

describe "Event and Invitation client round-trip" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  before do
    DROOM.setup url: "http://droom.test" do |c|
      c.request :json
      c.use Her::Middleware::JsonApiParser
      c.adapter :test, stubs
    end
  end

  after do
    stubs.verify_stubbed_calls
  end

  it "creates an event via POST /api/events" do
    stubs.post("/api/events") do
      [201, { 'Content-Type' => 'application/json' },
       { event: { id: 42, name: "Test Screening", start: "2026-05-01T09:00:00Z", event_type_id: 1 } }.to_json]
    end

    event = Droom::Event.create(name: "Test Screening", start: "2026-05-01T09:00:00Z", event_type_id: 1)
    expect(event.id).to eq(42)
    expect(event.name).to eq("Test Screening")
  end

  it "updates an event via PUT /api/events/:id" do
    stubs.put("/api/events/42") do
      [200, { 'Content-Type' => 'application/json' },
       { event: { id: 42, name: "Updated Screening", start: "2026-05-02T09:00:00Z", event_type_id: 1 } }.to_json]
    end

    event = Droom::Event.new(id: 42, name: "Test Screening")
    event.name = "Updated Screening"
    event.save
    expect(event.name).to eq("Updated Screening")
  end

  it "destroys an event via DELETE /api/events/:id" do
    stubs.delete("/api/events/42") do
      [200, { 'Content-Type' => 'application/json' }, ""]
    end

    event = Droom::Event.new(id: 42, name: "Test Screening")
    expect { event.destroy }.not_to raise_error
  end

  it "creates an invitation via POST /api/events/:event_id/invitations" do
    stubs.post("/api/events/42/invitations") do
      [201, { 'Content-Type' => 'application/json' },
       { invitation: { id: 99, event_id: 42, user_id: 7 } }.to_json]
    end

    invitation = Invitation.create(event_id: 42, user_id: 7)
    expect(invitation.id).to eq(99)
  end

  it "destroys an invitation via DELETE /api/events/:event_id/invitations/:id" do
    stubs.delete("/api/events/42/invitations/99") do
      [200, { 'Content-Type' => 'application/json' }, ""]
    end

    expect { Invitation.destroy(event_id: 42, id: 99) }.not_to raise_error
  end

  it "performs a full round-trip: create event → invite user → remove invitation → destroy event" do
    stubs.post("/api/events") do
      [201, { 'Content-Type' => 'application/json' },
       { event: { id: 42, name: "Screening", start: "2026-05-01T09:00:00Z", event_type_id: 1 } }.to_json]
    end
    stubs.post("/api/events/42/invitations") do
      [201, { 'Content-Type' => 'application/json' },
       { invitation: { id: 99, event_id: 42, user_id: 7 } }.to_json]
    end
    stubs.delete("/api/events/42/invitations/99") do
      [200, { 'Content-Type' => 'application/json' }, ""]
    end
    stubs.delete("/api/events/42") do
      [200, { 'Content-Type' => 'application/json' }, ""]
    end

    # Create event
    event = Droom::Event.create(name: "Screening", start: "2026-05-01T09:00:00Z", event_type_id: 1)
    expect(event.id).to eq(42)

    # Invite user
    invitation = event.invite_user(7)
    expect(invitation.id).to eq(99)

    # Remove invitation
    event.uninvite(99)

    # Destroy event
    event.destroy
  end
end

