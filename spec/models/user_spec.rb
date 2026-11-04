require "rails_helper"

RSpec.describe User, type: :model do
  describe "メールアドレスの重複バリデーション" do
    let!(:existing_user) { create(:user, email_address: "existing@example.com") }

    context "他のユーザーと同じメールアドレスを追加した場合" do
      let(:user) { create(:user, email_address: "unique@example.com") }

      it "具体的なアドレスを含むエラーメッセージが1つだけ表示される" do
        user.mail_addresses.build(address: "existing@example.com", confirmed_at: Time.current)
        user.valid?

        duplicate_errors = user.errors.full_messages.select { |msg| msg.include?("existing@example.com") }
        expect(duplicate_errors).to eq [ "メールアドレス「existing@example.com」はすでに存在します" ]
      end
    end

    context "自分の既存アドレスと同じアドレスを追加した場合" do
      let(:user) { create(:user, email_address: "myaddr@example.com") }

      it "具体的なアドレスを含むエラーメッセージが1つだけ表示される" do
        user.mail_addresses.build(address: "myaddr@example.com", confirmed_at: Time.current)
        user.valid?

        duplicate_errors = user.errors.full_messages.select { |msg| msg.include?("myaddr@example.com") }
        expect(duplicate_errors).to eq [ "メールアドレス「myaddr@example.com」はすでに存在します" ]
      end
    end
  end

  describe "#provisional?" do
    subject { build(:user, password: password, provisional: provisional) }

    context "provisional が明示的に設定されていない場合" do
      let(:provisional) { nil }

      context "password_digest がない場合" do
        let(:password) { nil }
        it { is_expected.to be_provisional }
      end

      context "password_digest がある場合" do
        let(:password) { "password123" }
        it { is_expected.not_to be_provisional }
      end
    end

    context "provisional が true の場合" do
      let(:provisional) { true }
      let(:password) { "password123" }
      it { is_expected.to be_provisional }
    end

    context "provisional が false の場合" do
      let(:provisional) { false }
      let(:password) { nil }
      it { is_expected.not_to be_provisional }
    end
  end

  describe "パスワードのバリデーション" do
    subject(:user) { build(:user, password: password, provisional: provisional) }

    context "provisional でない場合" do
      let(:provisional) { false }

      context "パスワードなし" do
        let(:password) { nil }
        it { is_expected.not_to be_valid }
      end

      context "パスワードあり" do
        let(:password) { "password123" }
        it { is_expected.to be_valid }
      end
    end

    context "provisional の場合" do
      let(:provisional) { true }

      context "パスワードなし" do
        let(:password) { nil }
        it { is_expected.to be_valid }
      end
    end

    context "既存ユーザーの場合" do
      let(:user) { create(:user) }

      it "パスワードを指定せずにsaveできる" do
        expect(user.save).to be true
      end
    end
  end
end
