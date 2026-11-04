require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "ログイン画面を表示する" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    context "パスワードが正しい場合" do
      context "有効で、メールアドレスが確認済みのユーザーの場合" do
        it "ログインしてダッシュボードに移る" do
          sign_in(user)

          expect(response).to redirect_to(root_path)
          get root_path
          expect(response).to have_http_status(:ok)
        end

        context "ログインが必要な画面を開こうとしていた場合" do
          before do
            get edit_profile_path
          end

          it "ログイン後に、開こうとしていた画面に移る" do
            sign_in(user)
            expect(response).to redirect_to(edit_profile_url)
          end
        end
      end

      context "無効化されているユーザーの場合" do
        let(:user) { create(:user, :disabled) }

        it "ログインせず、ログイン画面に戻る" do
          sign_in(user)

          expect(response).to redirect_to(new_session_path)
          get root_path
          expect(response).to redirect_to(new_session_path)
        end
      end

      context "メールアドレスが確認されていないユーザーの場合" do
        let(:user) { create(:user, :unconfirmed) }

        it "ログインせず、ログイン画面に戻る" do
          sign_in(user)

          expect(response).to redirect_to(new_session_path)
          get root_path
          expect(response).to redirect_to(new_session_path)
        end
      end
    end

    context "パスワードが誤っている場合" do
      it "ログインせず、ログイン画面に戻ってエラーを表示する" do
        sign_in(user, password: "wrong_password")

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq I18n.t("sessions.create.failure")
        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /session" do
    context "ログインしている場合" do
      before do
        sign_in(user)
      end

      it "ログアウトしてログイン画面に移る" do
        delete session_path

        expect(response).to redirect_to(new_session_path)
        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
