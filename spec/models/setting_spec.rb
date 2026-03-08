require "rails_helper"

RSpec.describe Setting, type: :model do
  let(:setting) { Setting.instance }

  describe "配信上限のバリデーション" do
    it "お知らせ配信数がメール配信数以下なら有効" do
      setting.daily_mail_delivery_limit = 100
      setting.daily_announcement_delivery_limit = 70
      expect(setting).to be_valid
    end

    it "お知らせ配信数がメール配信数と同じなら有効" do
      setting.daily_mail_delivery_limit = 100
      setting.daily_announcement_delivery_limit = 100
      expect(setting).to be_valid
    end

    it "お知らせ配信数がメール配信数を超える場合は無効" do
      setting.daily_mail_delivery_limit = 50
      setting.daily_announcement_delivery_limit = 70
      expect(setting).not_to be_valid
      expect(setting.errors[:daily_announcement_delivery_limit]).to be_present
    end

    it "メール配信数が空でもお知らせ配信数の比較でエラーにならない" do
      setting.daily_mail_delivery_limit = nil
      setting.daily_announcement_delivery_limit = 70
      expect(setting).not_to be_valid
      expect(setting.errors[:daily_mail_delivery_limit]).to be_present
    end
  end
end
