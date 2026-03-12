require "rails_helper"

RSpec.describe "Webhooks::Resend", type: :request do
  let(:announcement) do
    Announcement.create!(subject: "テスト", body: "本文", to_address: "admin@example.com", recipient_addresses: [ "a@example.com" ])
  end

  let(:delivery) do
    AnnouncementDelivery.create!(
      announcement: announcement,
      addresses: [ "user1@example.com", "user2@example.com" ],
      resend_ids: [ "resend_id_1", "resend_id_2" ],
      status: :requested,
      requested_at: Time.current
    )
  end

  def post_webhook(type:, email_id:, to: nil)
    post "/webhooks/resend", params: {
      type: type,
      data: { email_id: email_id, to: to || [ "user1@example.com" ] }
    }, as: :json
  end

  describe "POST /webhooks/resend" do
    it "delivery 作成時に Result が自動作成される" do
      expect(delivery.results.size).to eq(2)
      expect(delivery.results.map(&:resend_id)).to contain_exactly("resend_id_1", "resend_id_2")
      expect(delivery.results.map(&:address)).to contain_exactly("user1@example.com", "user2@example.com")
      expect(delivery.results).to all(have_attributes(event: nil))
    end

    it "配信済みイベントで Result の event を更新する" do
      delivery

      post_webhook(type: "email.delivered", email_id: "resend_id_1")

      expect(response).to have_http_status(:ok)
      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to eq("delivered")
    end

    it "バウンスイベントで Result の event を更新する" do
      delivery

      post_webhook(type: "email.bounced", email_id: "resend_id_2")

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_2")
      expect(result.event).to eq("bounced")
    end

    it "delivery_delayed → delivered に更新できる" do
      delivery
      post_webhook(type: "email.delivery_delayed", email_id: "resend_id_1")

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to eq("delivery_delayed")

      post_webhook(type: "email.delivered", email_id: "resend_id_1")

      expect(result.reload.event).to eq("delivered")
    end

    it "bounced/complained は上書きされない" do
      delivery
      post_webhook(type: "email.bounced", email_id: "resend_id_1")
      post_webhook(type: "email.delivered", email_id: "resend_id_1")

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to eq("bounced")
    end

    it "対応する Result がない resend_id は無視する" do
      post_webhook(type: "email.delivered", email_id: "unknown_id")

      expect(response).to have_http_status(:ok)
    end

    it "サポート外のイベントは無視する" do
      delivery

      post_webhook(type: "email.sent", email_id: "resend_id_1")

      expect(response).to have_http_status(:ok)
      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to be_nil
    end
  end
end
