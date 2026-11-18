require 'spec_helper'

describe "Event and Invitation client round-trip" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  def resource(type, id, attributes)
    { success: true, data: { type: type, id: id.to_s, attributes: attributes } }.to_json
  end

  before do
    DROOM.setup url: "http://droom.test" do |c|
      c.request :json
      c.use Her::Middleware::JsonApiParser
      c.adapter :test, stubs
    end
  end

  after { stubs.verify_stubbed_calls }

  it "creates an event and reads its server UUID from the JSON:API response" do
    stubs.post("/api/events") do
      [201, { 'Content-Type' => 'application/json' },
        resource("events", 42, name: "Deadline", uuid: "stable-uuid")]
    end
    event = Droom::Event.create(name: "Deadline", start: "2026-12-31T00:00:00+08:00")
    expect(event.id).to eq("42")
    expect(event.uuid).to eq("stable-uuid")
  end

  it "updates a deadline by UUID with exactly one Rails event wrapper" do
    stubs.put("/api/events/stable-uuid") do |env|
      expect(JSON.parse(env.body)).to eq("event" => {
        "name" => "Updated deadline", "all_day" => true, "url" => "https://apps.example.test/screening"
      })
      [200, { 'Content-Type' => 'application/json' },
        resource("events", 42, uuid: "stable-uuid", name: "Updated deadline")]
    end
    event = Droom::Event.update_by_uuid("stable-uuid",
      name: "Updated deadline", all_day: true, url: "https://apps.example.test/screening")
    expect(event.uuid).to eq("stable-uuid")
    expect(event.name).to eq("Updated deadline")
  end

  it "raises on failed deadline updates rather than hiding validation errors" do
    stubs.put("/api/events/stable-uuid") do
      [422, { 'Content-Type' => 'application/json' }, { errors: ["Invalid deadline"] }.to_json]
    end
    expect { Droom::Event.update_by_uuid("stable-uuid", start: nil) }.to raise_error(/HTTP 422/)
  end

  it "does not report successful event deletion on an API failure" do
    stubs.delete("/api/events/stable-uuid") do
      [503, { 'Content-Type' => 'application/json' }, { errors: ["Unavailable"] }.to_json]
    end
    expect { Droom::Event.destroy_by_uuid("stable-uuid") }.to raise_error(/HTTP 503/)
  end

  it "creates, lists and removes a judge's event invitation using event UUIDs" do
    stubs.post("/api/events/stable-uuid/invitations") do |env|
      expect(JSON.parse(env.body)).to eq("invitation" => { "user_id" => "judge-uid" })
      [201, { 'Content-Type' => 'application/json' },
        resource("invitations", 99, event_id: "stable-uuid", user_uid: "judge-uid")]
    end
    stubs.get("/api/events/stable-uuid/invitations") do
      [200, { 'Content-Type' => 'application/json' }, {
        success: true, data: [{ id: "99", type: "invitations", attributes: {
          event_id: "stable-uuid", user_uid: "judge-uid"
        } }]
      }.to_json]
    end
    stubs.delete("/api/events/stable-uuid/invitations/99") do
      [200, { 'Content-Type' => 'application/json' }, { success: true }.to_json]
    end
    invitation = Invitation.create(event_id: "stable-uuid", user_id: "judge-uid")
    expect(invitation.id).to eq("99")
    invitations = Invitation.for_event("stable-uuid")
    expect(invitations.map(&:user_uid)).to eq(["judge-uid"])
    expect { invitation.destroy }.not_to raise_error
  end

  it "raises when invitation retrieval fails rather than treating the audience as empty" do
    stubs.get("/api/events/stable-uuid/invitations") do
      [503, { 'Content-Type' => 'application/json' }, { errors: ["Unavailable"] }.to_json]
    end
    expect { Invitation.for_event("stable-uuid") }.to raise_error(/HTTP 503/)
  end

  it "raises when removing a former judge fails" do
    stubs.delete("/api/events/stable-uuid/invitations/99") do
      [503, { 'Content-Type' => 'application/json' }, { errors: ["Unavailable"] }.to_json]
    end
    expect { Invitation.destroy(event_id: "stable-uuid", id: 99) }.to raise_error(/HTTP 503/)
  end
end
