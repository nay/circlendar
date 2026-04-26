require "rails_helper"

RSpec.describe "Admin::Settings", type: :request do
  let(:admin_user) do
    User.create!(
      email_address: "admin@example.com",
      password: "password123",
      role: "admin",
      confirmed_at: Time.current
    )
  end

  let!(:admin_member) { Member.create!(name: "管理者", user: admin_user) }

  before do
    post session_path, params: { email_address: admin_user.email_address, password: "password123" }
  end

  describe "GET /admin/setting/edit" do
    it "200を返す" do
      get edit_admin_setting_path
      expect(response).to have_http_status(:ok)
    end

    it "LINE公式アカウントURL欄と紹介用文章テンプレート欄が表示される" do
      get edit_admin_setting_path
      expect(response.body).to include("setting[line_official_account_url]")
      expect(response.body).to include("setting[referral_share_template]")
    end
  end

  describe "PATCH /admin/setting" do
    context "LINE URLと紹介テンプレートを更新した場合" do
      let(:params) do
        {
          line_official_account_url: "https://line.me/R/ti/p/@example",
          referral_share_template: "カスタム文言 %{circle_name}"
        }
      end

      it "値が保存される" do
        patch admin_setting_path, params: { setting: params }

        setting = Setting.instance
        expect(setting.line_official_account_url).to eq "https://line.me/R/ti/p/@example"
        expect(setting.referral_share_template).to eq "カスタム文言 %{circle_name}"
      end
    end

    context "テンプレートを空文字で更新した場合" do
      it "空文字が保存される" do
        patch admin_setting_path, params: { setting: { referral_share_template: "" } }

        setting = Setting.instance
        expect(setting.referral_share_template).to eq ""
      end
    end
  end
end
