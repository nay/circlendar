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
    it "配信済みイベントで Result を作成する" do
      delivery # ensure created

      post_webhook(type: "email.delivered", email_id: "resend_id_1")

      expect(response).to have_http_status(:ok)
      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result).to be_present
      expect(result.event).to eq("delivered")
      expect(result.address).to eq("user1@example.com")
      expect(result.announcement_delivery).to eq(delivery)
    end

    it "バウンスイベントで Result を作成する" do
      delivery

      post_webhook(type: "email.bounced", email_id: "resend_id_2", to: [ "user2@example.com" ])

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_2")
      expect(result.event).to eq("bounced")
      expect(result.address).to eq("user2@example.com")
    end

    it "既存の Result を更新する（delivery_delayed → delivered）" do
      delivery
      post_webhook(type: "email.delivery_delayed", email_id: "resend_id_1")

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to eq("delivery_delayed")

      post_webhook(type: "email.delivered", email_id: "resend_id_1")

      expect(result.reload.event).to eq("delivered")
    end

    it "対応する delivery がない場合は無視する" do
      post_webhook(type: "email.delivered", email_id: "unknown_id")

      expect(response).to have_http_status(:ok)
      expect(AnnouncementDeliveryResult.count).to eq(0)
    end

    it "サポート外のイベントは無視する" do
      delivery

      post_webhook(type: "email.sent", email_id: "resend_id_1")

      expect(response).to have_http_status(:ok)
      expect(AnnouncementDeliveryResult.count).to eq(0)
    end

    it "to がない場合は resend_id からアドレスを照合する" do
      delivery

      post "/webhooks/resend", params: {
        type: "email.delivered",
        data: { email_id: "resend_id_2" }
      }, as: :json

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_2")
      expect(result.address).to eq("user2@example.com")
    end
  end
end
