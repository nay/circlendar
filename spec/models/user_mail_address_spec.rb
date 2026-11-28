require "rails_helper"

RSpec.describe UserMailAddress, type: :model do
  describe ".find_with_correct_password" do
    # 応答時間からアドレスの有無や状態を推し量れないよう、どの経路でも bcrypt の計算は1回にそろえる
    def expect_bcrypt_once
      expect(BCrypt::Engine).to receive(:hash_secret).once.and_call_original
    end

    context "パスワードが空の場合" do
      let!(:mail_address) { create(:user, password: "password123").mail_addresses.first } # ユーザーを作るときの bcrypt を数えないよう、先に作っておく

      it "アドレスの有無によらず nil を返し、bcrypt を計算しない" do
        expect(BCrypt::Engine).not_to receive(:hash_secret)
        expect(UserMailAddress.find_with_correct_password(address: mail_address.address, password: "")).to be_nil
        expect(UserMailAddress.find_with_correct_password(address: "nobody@example.com", password: "")).to be_nil
      end
    end

    context "パスワードが入力されている場合" do
      context "アドレスが登録されていない場合" do
        it "nil を返し、bcrypt を1回計算する" do
          expect_bcrypt_once
          expect(UserMailAddress.find_with_correct_password(address: "nobody@example.com", password: "password123")).to be_nil
        end
      end

      context "アドレスが登録されている場合" do
        let!(:mail_address) { user.mail_addresses.first } # ユーザーを作るときの bcrypt を数えないよう、先に作っておく

        context "パスワードを設定済みのユーザーの場合" do
          context "パスワードが正しい場合" do
            context "有効で、アドレスが確認済みのユーザーの場合" do
              let(:user) { create(:user, password: "password123", confirmed_at: Time.current) }

              it "そのアドレスを返し、bcrypt を1回計算する" do
                expect_bcrypt_once
                expect(UserMailAddress.find_with_correct_password(address: mail_address.address, password: "password123")).to eq mail_address
              end
            end

            context "有効で、アドレスが確認されていないユーザーの場合" do
              let(:user) { create(:user, :unconfirmed, password: "password123") }

              it "確認されていないそのアドレスを返し、bcrypt を1回計算する" do
                expect_bcrypt_once
                expect(UserMailAddress.find_with_correct_password(address: mail_address.address, password: "password123")).to eq mail_address
              end
            end

            context "無効化されているユーザーの場合" do
              let(:user) { create(:user, :disabled, password: "password123") }

              it "nil を返し、bcrypt を1回計算する" do
                expect_bcrypt_once
                expect(UserMailAddress.find_with_correct_password(address: mail_address.address, password: "password123")).to be_nil
              end
            end
          end

          context "パスワードが誤っている場合" do
            let(:user) { create(:user, password: "password123") }

            it "nil を返し、bcrypt を1回計算する" do
              expect_bcrypt_once
              expect(UserMailAddress.find_with_correct_password(address: mail_address.address, password: "wrong_password")).to be_nil
            end
          end
        end

        context "仮登録で、パスワードが未設定のユーザーの場合" do
          let(:user) { create(:user, :provisional) }

          it "nil を返し、bcrypt を1回計算する" do
            expect_bcrypt_once
            expect(UserMailAddress.find_with_correct_password(address: mail_address.address, password: "password123")).to be_nil
          end
        end
      end
    end
  end
end
