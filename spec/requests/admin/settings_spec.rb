require "rails_helper"

RSpec.describe "Admin::Settings", type: :request do
  context "ログインしていない場合" do
    it "設定画面を開くと、ログイン画面に移る" do
      get edit_admin_setting_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "一般メンバーとしてログインしている場合" do
    before do
      sign_in(create(:user))
    end

    it "設定画面を開くと、404を返す" do
      get edit_admin_setting_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "管理者としてログインしている場合" do
    before do
      sign_in(create(:user, :admin))
    end

    describe "GET /admin/setting/edit" do
      before do
        Setting.instance.update!(circle_name: "元のサークル名")
      end

      it "設定画面を表示する" do
        get edit_admin_setting_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("元のサークル名")
      end
    end

    describe "PATCH /admin/setting" do
      before do
        Setting.instance.update!(circle_name: "元のサークル名")
      end

      context "入力が正しい場合" do
        it "設定を更新し、設定画面に移る" do
          patch admin_setting_path, params: { setting: { circle_name: "新しいサークル名", announcement_batch_size: 20 } }

          expect(response).to redirect_to(edit_admin_setting_path)
          expect(Setting.first).to have_attributes(circle_name: "新しいサークル名", announcement_batch_size: 20)
        end
      end

      context "サークル名が空の場合" do
        it "設定を更新せず、設定画面を再表示する" do
          patch admin_setting_path, params: { setting: { circle_name: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(Setting.first.circle_name).to eq "元のサークル名"
        end
      end
    end

    describe "POST /admin/setting/generate_signup_token" do
      it "サインアップトークンを発行し、設定画面に移る" do
        expect {
          post generate_signup_token_admin_setting_path
        }.to change { Setting.instance.reload.signup_token }.from(nil)

        expect(response).to redirect_to(edit_admin_setting_path)
      end
    end
  end
end
