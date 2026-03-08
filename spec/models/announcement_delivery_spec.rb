require "rails_helper"

RSpec.describe MailDelivery::Announcement, type: :model do
  let(:announcement) { Announcement.create!(subject: "テスト", body: "本文", to_address: "admin@example.com", bcc_addresses: [ "user@example.com" ]) }

  describe "#request_send!" do
    let(:delivery) { MailDelivery::Announcement.create!(announcement: announcement, address: "user@example.com") }

    it "FakeResendClient 経由で送信し status を requested にする" do
      delivery.request_send!(from: "test@example.com", subject: "テスト", body: "本文", reply_to: "admin@example.com")

      expect(delivery.reload.status).to eq("requested")
      expect(delivery.requested_at).to be_present
      expect(delivery.resend_id).to start_with("fake_")
    end

    context "scheduled_at が設定されている場合" do
      let(:delivery) do
        MailDelivery::Announcement.create!(
          announcement: announcement,
          address: "user@example.com",
          scheduled_at: 1.day.from_now.in_time_zone("Asia/Tokyo").change(hour: 9)
        )
      end

      it "scheduled_at を含めて送信する" do
        delivery.request_send!(from: "test@example.com", subject: "テスト", body: "本文", reply_to: "admin@example.com")

        expect(delivery.reload.status).to eq("requested")
      end
    end
  end
end
