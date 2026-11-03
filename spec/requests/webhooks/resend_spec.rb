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
      expect(delivery.results).to all(have_attributes(event: "requested"))
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

    it "delivered は delivery_delayed で逆行しない" do
      delivery
      post_webhook(type: "email.delivered", email_id: "resend_id_1")
      post_webhook(type: "email.delivery_delayed", email_id: "resend_id_1")

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to eq("delivered")
    end

    it "delivered → complained は許可される" do
      delivery
      post_webhook(type: "email.delivered", email_id: "resend_id_1")
      post_webhook(type: "email.complained", email_id: "resend_id_1")

      result = AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1")
      expect(result.event).to eq("complained")
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
      expect(result.event).to eq("requested")
    end

    context "署名の secret が設定されている場合" do
      let(:secret) { "whsec_#{Base64.strict_encode64("test-signing-secret")}" }
      let(:body) { { type: "email.delivered", data: { email_id: "resend_id_1" } }.to_json }
      let(:msg_id) { "msg_test" }
      let(:timestamp) { Time.current.to_i.to_s }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RESEND_WEBHOOK_SIGNING_SECRET").and_return(secret)
      end

      def post_signed_webhook
        post webhooks_resend_path, params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "svix-id" => msg_id,
          "svix-timestamp" => timestamp,
          "svix-signature" => signature
        }
      end

      context "正しい署名の場合" do
        let(:signature) { Svix::Webhook.new(secret).sign(msg_id, timestamp, body) }

        it "受け付けて Result の event を更新する" do
          delivery

          post_signed_webhook

          expect(response).to have_http_status(:ok)
          expect(AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1").event).to eq("delivered")
        end
      end

      context "別の secret で作った署名の場合" do
        let(:signature) { Svix::Webhook.new("whsec_#{Base64.strict_encode64("other-signing-secret")}").sign(msg_id, timestamp, body) }

        it "401 を返し、Result の event を更新しない" do
          delivery

          post_signed_webhook

          expect(response).to have_http_status(:unauthorized)
          expect(AnnouncementDeliveryResult.find_by(resend_id: "resend_id_1").event).to eq("requested")
        end
      end
    end
  end
end
