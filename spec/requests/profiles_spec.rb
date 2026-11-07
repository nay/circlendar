require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, name: "元の名前") }

  describe "GET /profile/edit" do
    context "ログインしていない場合" do
      it "ログイン画面に移る" do
        get edit_profile_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログインしている場合" do
      before do
        sign_in(user)
      end

      it "プロフィールの編集画面を表示する" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("元の名前")
      end
    end
  end

  describe "PATCH /profile" do
    let(:params) { { user: { name: "新しい名前", password: password, password_confirmation: password_confirmation } } }

    context "ログインしていない場合" do
      it "プロフィールを変更せず、ログイン画面に移る" do
        patch profile_path, params: { user: { name: "新しい名前" } }

        expect(response).to redirect_to(new_session_path)
        expect(user.reload.name).to eq "元の名前"
      end
    end

    context "ログインしている場合" do
      before do
        sign_in(user)
      end

      context "パスワード欄が空の場合" do
        let(:password) { "" }
        let(:password_confirmation) { "" }

        it "プロフィールを変更し、パスワードは変えずに、編集画面に移る" do
          patch profile_path, params: params

          expect(response).to redirect_to(edit_profile_path)
          user.reload
          expect(user.name).to eq "新しい名前"
          expect(user.authenticate("password123")).to be_truthy
        end
      end

      context "新しいパスワードを入力し、確認用と一致する場合" do
        let(:password) { "new_password" }
        let(:password_confirmation) { "new_password" }

        it "パスワードを変更する" do
          patch profile_path, params: params

          expect(response).to redirect_to(edit_profile_path)
          expect(user.reload.authenticate("new_password")).to be_truthy
        end
      end

      context "新しいパスワードを入力し、確認用と一致しない場合" do
        let(:password) { "new_password" }
        let(:password_confirmation) { "other_password" }

        it "何も変更せず、編集画面を再表示する" do
          patch profile_path, params: params

          expect(response).to have_http_status(:unprocessable_content)
          user.reload
          expect(user.name).to eq "元の名前"
          expect(user.authenticate("password123")).to be_truthy
        end
      end
    end
  end
end
