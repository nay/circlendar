require "rails_helper"

RSpec.describe "Confirmations", type: :request do
  describe "GET /confirm" do
    let(:user) { create(:user, :unconfirmed) }

    context "確認用のトークンが正しい場合" do
      context "有効なユーザーの場合" do
        it "メールアドレスを確認済みにし、ログインしてダッシュボードに移る" do
          get confirm_path(token: user.confirmation_token)

          expect(response).to redirect_to(root_path)
          expect(user.reload).to be_confirmed
          get root_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "無効化されているユーザーの場合" do
        let(:user) { create(:user, :unconfirmed, :disabled) }

        it "メールアドレスを確認済みにせず、ログイン画面に移る" do
          get confirm_path(token: user.confirmation_token)

          expect(response).to redirect_to(new_session_path)
          expect(user.reload).not_to be_confirmed
        end
      end
    end

    context "確認用のトークンが正しくない場合" do
      it "メールアドレスを確認済みにせず、ログイン画面に移る" do
        get confirm_path(token: "invalid_token")

        expect(response).to redirect_to(new_session_path)
        expect(user.reload).not_to be_confirmed
      end
    end
  end
end
