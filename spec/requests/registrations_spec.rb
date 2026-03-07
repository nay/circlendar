require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:signup_token) { "test_signup_token" }

  before do
    Setting.instance.update!(signup_token: signup_token)
  end

  describe "POST /signup/:token" do
    let(:user_params) do
      {
        email_address: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123",
        receives_announcements: "1",
        name: "テストユーザー",
        organization_name: "テスト団体",
        rank: "d"
      }
    end

    context "新規メールアドレスの場合" do
      it "ユーザーが作成され確認メール送信画面にリダイレクトする" do
        expect {
          post signup_path(token: signup_token), params: { user: user_params }
        }.to change(User, :count).by(1).and change(Member, :count).by(1)

        expect(response).to redirect_to(confirmation_sent_path)

        user = User.last
        expect(user.email_address).to eq "newuser@example.com"
        expect(user.member.name).to eq "テストユーザー"
        expect(user.confirmed_at).to be_nil
        expect(user.confirmation_token).to be_present
      end
    end

    context "既存ユーザーが仮登録（管理者作成・パスワードなし）の場合" do
      let(:other_mail_address_count) { 0 }
      let!(:existing_user) do
        user = User.create!(
          email_address: "newuser@example.com",
          provisional: true,
          role: "member",
          confirmed_at: Time.current
        )
        other_mail_address_count.times do |i|
          user.mail_addresses.create!(address: "other#{i}@example.com", confirmed_at: Time.current)
        end
        user
      end
      let!(:existing_member) { Member.create!(name: "管理者が設定した名前", user: existing_user) }

      it "既存ユーザーを上書きし確認メール送信画面にリダイレクトする" do
        expect {
          post signup_path(token: signup_token), params: { user: user_params }
        }.to change(User, :count).by(0).and change(Member, :count).by(0)

        expect(response).to redirect_to(confirmation_sent_path)

        existing_user.reload
        expect(existing_user.authenticate("password123")).to be_truthy
        expect(existing_user.member.name).to eq "テストユーザー"
        expect(existing_user.member.organization_name).to eq "テスト団体"
        expect(existing_user.confirmed_at).to be_nil
        expect(existing_user.confirmation_token).to be_present
      end

      context "複数のメールアドレスがある場合" do
        let(:other_mail_address_count) { 2 }

        it "サインアップに使用したメールアドレス以外は削除される" do
          expect {
            post signup_path(token: signup_token), params: { user: user_params }
          }.to change { existing_user.mail_addresses.count }.from(3).to(1)

          existing_user.reload
          expect(existing_user.mail_addresses.sole.address).to eq "newuser@example.com"
        end
      end
    end

    context "既存ユーザーがログイン済みの場合" do
      let!(:existing_user) do
        User.create!(
          email_address: "newuser@example.com",
          password: "existing_password",
          role: "member",
          confirmed_at: Time.current,
          last_accessed_at: 1.day.ago
        )
      end
      let!(:existing_member) { Member.create!(name: "既存ユーザー", user: existing_user) }

      it "ログイン画面にリダイレクトしメールアドレスを引き継ぐ" do
        post signup_path(token: signup_token), params: { user: user_params }

        expect(response).to redirect_to(new_session_path(email_address: "newuser@example.com"))
        expect(flash[:notice]).to be_present

        existing_user.reload
        expect(existing_user.authenticate("existing_password")).to be_truthy
        expect(existing_user.member.name).to eq "既存ユーザー"
      end
    end
  end
end
