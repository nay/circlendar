require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  context "ログインしていない場合" do
    it "一覧を開くと、ログイン画面に移る" do
      get admin_users_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "一般メンバーとしてログインしている場合" do
    before do
      sign_in(create(:user))
    end

    it "一覧を開くと、404を返す" do
      get admin_users_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "管理者としてログインしている場合" do
    let(:admin) { create(:user, :admin, email_address: "admin@example.com") }

    before do
      sign_in(admin)
    end

    describe "GET /admin/users" do
      context "検索しない場合" do
        it "一覧を表示する" do
          get admin_users_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "メールアドレスで検索した場合" do
        before do
          create(:user, email_address: "other@example.com", name: "他のユーザー")
        end

        it "一致するユーザーだけを表示する" do
          get admin_users_path, params: { q: "other" }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("他のユーザー")
          expect(response.body).not_to include("admin@example.com")
        end
      end
    end

    describe "GET /admin/users/:id" do
      let(:user) { create(:user, name: "対象のユーザー") }

      it "ユーザーの詳細を表示する" do
        get admin_user_path(user)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("対象のユーザー")
      end
    end

    describe "GET /admin/users/new" do
      it "新規作成の画面を表示する" do
        get new_admin_user_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/users" do
      let(:params) do
        {
          name: "新しいユーザー",
          email_address: "new@example.com",
          organization_name: "テスト団体",
          rank: "d",
          role: "member",
          receives_announcements: "1",
          password: password,
          password_confirmation: password
        }
      end

      context "メールアドレスがほかのユーザーと重ならない場合" do
        context "パスワードが空の場合" do
          let(:password) { "" }

          it "仮登録としてユーザーを作成し、詳細画面に移る" do
            expect {
              post admin_users_path, params: { user: params }
            }.to change(User, :count).by(1)

            created_user = User.last
            expect(response).to redirect_to(admin_user_path(created_user))
            expect(created_user.password_digest).to be_nil
            expect(created_user.provisional?).to be true
            expect(created_user.confirmed?).to be true
          end
        end

        context "パスワードを入力した場合" do
          let(:password) { "password123" }

          it "通常のユーザーを作成し、詳細画面に移る" do
            expect {
              post admin_users_path, params: { user: params }
            }.to change(User, :count).by(1)

            created_user = User.last
            expect(response).to redirect_to(admin_user_path(created_user))
            expect(created_user.password_digest).to be_present
            expect(created_user.provisional?).to be false
          end
        end
      end

      context "メールアドレスがほかのユーザーと重なる場合" do
        let(:password) { "password123" }

        before do
          create(:user, email_address: "new@example.com")
        end

        it "ユーザーを作成せず、新規作成の画面を再表示する" do
          expect {
            post admin_users_path, params: { user: params }
          }.not_to change(User, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "GET /admin/users/:id/edit" do
      let(:user) { create(:user) }

      it "編集画面を表示する" do
        get edit_admin_user_path(user)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/users/:id" do
      context "ほかのユーザーを更新する場合" do
        let!(:user) { create(:user, name: "元の名前") }

        context "名前を変えた場合" do
          it "ユーザーを更新し、詳細画面に移る" do
            patch admin_user_path(user), params: { user: { name: "新しい名前" } }

            expect(response).to redirect_to(admin_user_path(user))
            expect(user.reload.name).to eq "新しい名前"
          end
        end

        context "仮登録に戻した場合" do
          it "パスワードを消して仮登録にする" do
            patch admin_user_path(user), params: { user: { provisional: "1" } }

            user.reload
            expect(user.password_digest).to be_nil
            expect(user.provisional?).to be true
          end
        end

        context "無効にした場合" do
          it "ユーザーを無効にする" do
            patch admin_user_path(user), params: { user: { disabled: "1" } }

            expect(response).to redirect_to(admin_user_path(user))
            expect(user.reload).to be_disabled
          end
        end

        context "メールアドレスの欄を足すボタンを押した場合" do
          it "保存せず、欄を足した編集画面を表示する" do
            expect {
              patch admin_user_path(user), params: { user: { name: "新しい名前" }, add_mail_address: "1" }
            }.not_to change { user.mail_addresses.count }

            expect(response).to have_http_status(:unprocessable_content)
            expect(user.reload.name).to eq "元の名前"
          end
        end

        context "メールアドレスの欄を消すボタンを押した場合" do
          before do
            user.mail_addresses.create!(address: "second@example.com", confirmed_at: Time.current)
          end

          it "保存せず、欄を消した編集画面を表示する" do
            expect {
              patch admin_user_path(user), params: { user: { name: "新しい名前" }, remove_mail_address: "1" }
            }.not_to change { user.mail_addresses.count }

            expect(response).to have_http_status(:unprocessable_content)
            expect(user.reload.name).to eq "元の名前"
          end
        end
      end

      context "自分自身を更新する場合" do
        context "無効にしようとした場合" do
          it "無効にせず、編集画面に戻ってエラーを表示する" do
            patch admin_user_path(admin), params: { user: { disabled: "1" } }

            expect(response).to redirect_to(edit_admin_user_path(admin))
            expect(flash[:alert]).to be_present
            expect(admin.reload).not_to be_disabled
          end
        end

        context "権限を変えようとした場合" do
          it "権限を変えない" do
            patch admin_user_path(admin), params: { user: { role: "member" } }

            expect(response).to redirect_to(admin_user_path(admin))
            expect(admin.reload).to be_admin
          end
        end
      end
    end

    describe "DELETE /admin/users/:id" do
      context "ほかのユーザーを削除する場合" do
        let!(:user) { create(:user) }

        it "ユーザーを削除し、一覧に移る" do
          expect {
            delete admin_user_path(user)
          }.to change(User, :count).by(-1)

          expect(response).to redirect_to(admin_users_path)
        end
      end

      context "自分自身を削除する場合" do
        it "削除せず、詳細画面に戻ってエラーを表示する" do
          expect {
            delete admin_user_path(admin)
          }.not_to change(User, :count)

          expect(response).to redirect_to(admin_user_path(admin))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
