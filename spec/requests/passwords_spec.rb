require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "パスワード再設定の画面を表示する" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    context "登録済みのメールアドレスの場合" do
      let(:user) { create(:user) }

      it "再設定のメールを送り、ログイン画面に移る" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "仮登録のユーザーのメールアドレスの場合" do
      let(:user) { create(:user, :provisional) }

      it "再設定のメールを送らず、ログイン画面に移る" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.not_to have_enqueued_mail(PasswordsMailer, :reset)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "登録されていないメールアドレスの場合" do
      it "再設定のメールを送らず、ログイン画面に移る" do
        expect {
          post passwords_path, params: { email_address: "unknown@example.com" }
        }.not_to have_enqueued_mail(PasswordsMailer, :reset)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    context "トークンが正しい場合" do
      let(:user) { create(:user) }

      it "新しいパスワードの入力画面を表示する" do
        get edit_password_path(user.password_reset_token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "トークンが正しくない場合" do
      it "パスワード再設定の画面に戻る" do
        get edit_password_path("invalid_token")
        expect(response).to redirect_to(new_password_path)
      end
    end
  end

  describe "PATCH /passwords/:token" do
    let(:user) { create(:user) }

    context "確認用のパスワードが一致する場合" do
      it "パスワードを変更し、ログイン画面に移る" do
        patch password_path(user.password_reset_token), params: { password: "new_password", password_confirmation: "new_password" }

        expect(response).to redirect_to(new_session_path)
        expect(user.reload.authenticate("new_password")).to be_truthy
      end
    end

    context "確認用のパスワードが一致しない場合" do
      it "パスワードを変更せず、新しいパスワードの入力画面に戻る" do
        token = user.password_reset_token
        patch password_path(token), params: { password: "new_password", password_confirmation: "other_password" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(user.reload.authenticate("password123")).to be_truthy
      end
    end
  end
end
