require "rails_helper"

RSpec.describe User, type: :model do
  describe "メールアドレスの重複バリデーション" do
    let!(:existing_user) do
      User.create!(
        password: "password123",
        role: "member",
        mail_addresses: [ UserMailAddress.new(address: "existing@example.com", confirmed_at: Time.current) ]
      )
    end

    context "他のユーザーと同じメールアドレスを追加した場合" do
      let(:user) do
        User.create!(
          password: "password123",
          role: "member",
          mail_addresses: [ UserMailAddress.new(address: "unique@example.com", confirmed_at: Time.current) ]
        )
      end

      it "具体的なアドレスを含むエラーメッセージが1つだけ表示される" do
        user.mail_addresses.build(address: "existing@example.com", confirmed_at: Time.current)
        user.valid?

        duplicate_errors = user.errors.full_messages.select { |msg| msg.include?("existing@example.com") }
        expect(duplicate_errors).to eq [ "メールアドレス「existing@example.com」はすでに存在します" ]
      end
    end

    context "自分の既存アドレスと同じアドレスを追加した場合" do
      let(:user) do
        User.create!(
          password: "password123",
          role: "member",
          mail_addresses: [ UserMailAddress.new(address: "myaddr@example.com", confirmed_at: Time.current) ]
        )
      end

      it "具体的なアドレスを含むエラーメッセージが1つだけ表示される" do
        user.mail_addresses.build(address: "myaddr@example.com", confirmed_at: Time.current)
        user.valid?

        duplicate_errors = user.errors.full_messages.select { |msg| msg.include?("myaddr@example.com") }
        expect(duplicate_errors).to eq [ "メールアドレス「myaddr@example.com」はすでに存在します" ]
      end
    end
  end
end
