require "rails_helper"

RSpec.describe UserMailAddress, type: :model do
  describe ".authenticate" do
    # 応答時間からアドレスの有無や状態を推し量れないよう、どの経路でも bcrypt の計算は1回にそろえる
    def expect_bcrypt_once
      expect(BCrypt::Engine).to receive(:hash_secret).once.and_call_original
    end

    context "アドレスが登録されていない場合" do
      it "nil を返し、bcrypt を1回計算する" do
        expect_bcrypt_once
        expect(UserMailAddress.authenticate(address: "nobody@example.com", password: "password123")).to be_nil
      end
    end

    context "アドレスが登録されている場合" do
      let!(:mail_address) { user.mail_addresses.first }

      context "パスワードを設定済みのユーザーの場合" do
        let(:user) { create(:user) }

        context "パスワードが正しい場合" do
          context "有効なユーザーの場合" do
            it "そのアドレスを返し、bcrypt を1回計算する" do
              expect_bcrypt_once
              expect(UserMailAddress.authenticate(address: mail_address.address, password: "password123")).to eq mail_address
            end
          end

          context "無効化されているユーザーの場合" do
            let(:user) { create(:user, :disabled) }

            it "nil を返し、bcrypt を1回計算する" do
              expect_bcrypt_once
              expect(UserMailAddress.authenticate(address: mail_address.address, password: "password123")).to be_nil
            end
          end
        end

        context "パスワードが誤っている場合" do
          it "nil を返し、bcrypt を1回計算する" do
            expect_bcrypt_once
            expect(UserMailAddress.authenticate(address: mail_address.address, password: "wrong_password")).to be_nil
          end
        end

        context "パスワードが空の場合" do
          it "nil を返し、bcrypt を計算しない" do
            expect(BCrypt::Engine).not_to receive(:hash_secret)
            expect(UserMailAddress.authenticate(address: mail_address.address, password: "")).to be_nil
          end
        end
      end

      context "仮登録で、パスワードが未設定のユーザーの場合" do
        let(:user) { create(:user, :provisional) }

        it "nil を返し、bcrypt を1回計算する" do
          expect_bcrypt_once
          expect(UserMailAddress.authenticate(address: mail_address.address, password: "password123")).to be_nil
        end
      end
    end
  end
end
