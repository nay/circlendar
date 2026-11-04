require "rails_helper"

RSpec.describe "Admin::Events", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:event) { create(:event, status: :published) }

  before do
    post session_path, params: { email_address: admin_user.email_address, password: "password123" }
  end

  describe "GET /admin/events/:id" do
    it "200を返す" do
      get admin_event_path(event)
      expect(response).to have_http_status(:ok)
    end

    context "出欠回答がある場合" do
      before do
        create(:attendance, event: event, status: :attending)
      end

      it "200を返す" do
        get admin_event_path(event)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
