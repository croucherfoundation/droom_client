require "spec_helper"

describe User do
  describe ".eligible_event_staff" do
    it "uses per-request authentication and returns office staff user objects" do
      parsed = { data: [{ uid: "office-1", given_name: "Office", family_name: "Staff" }], errors: [], metadata: {} }
      expect(described_class).to receive(:get_raw).with(
        "/api/users/eligible_event_staff",
        _headers: { "Authorization" => 'Token token="caller-session"' }
      ).and_yield(parsed, double(status: 200))

      expect(described_class.eligible_event_staff(session_token: "caller-session").map(&:uid)).to eq(["office-1"])
    end

    it "preserves an authoritative empty directory" do
      allow(described_class).to receive(:get_raw).and_yield({ data: [], errors: [], metadata: {} }, double(status: 200))

      expect(described_class.eligible_event_staff(session_token: "caller-session")).to be_empty
    end

    it "distinguishes upstream forbidden access" do
      allow(described_class).to receive(:get_raw).and_yield({ data: {} }, double(status: 403))

      expect { described_class.eligible_event_staff(session_token: "caller-session") }
        .to raise_error(User::StaffDirectoryAccessDenied)
    end

    it "does not turn a failed request into an empty success" do
      allow(described_class).to receive(:get_raw).and_yield({ data: [] }, double(status: 502))

      expect(described_class.eligible_event_staff(session_token: "caller-session")).to be_nil
    end

    it "does not request the directory without a caller session" do
      expect(described_class).not_to receive(:get_raw)

      expect(described_class.eligible_event_staff(session_token: nil)).to be_nil
    end
  end
end