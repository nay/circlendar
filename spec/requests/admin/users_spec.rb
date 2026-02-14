require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:user) do
    User.create!(
      email_address: "admin@example.com",
      password: "password123",
      role: "admin",
      confirmed_at: Time.current
    )
  end

  let!(:member) do
    Member.create!(name: "管理者", user: user)
  end

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /admin/users" do
    it "200を返す" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
    end
  end
end
