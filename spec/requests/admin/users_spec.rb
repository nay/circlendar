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

    context "メールアドレスで検索した場合" do
      let!(:other_user) do
        u = User.create!(
          email_address: "other@example.com",
          password: "password123",
          role: "member",
          confirmed_at: Time.current
        )
        Member.create!(name: "他のユーザー", user: u)
        u
      end

      it "一致するユーザーが表示される" do
        get admin_users_path, params: { q: "other" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("他のユーザー")
      end

      it "一致しないユーザーは表示されない" do
        get admin_users_path, params: { q: "other" }
        expect(response.body).not_to include("admin@example.com")
      end
    end
  end
end
