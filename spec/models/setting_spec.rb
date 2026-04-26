require "rails_helper"

RSpec.describe Setting, type: :model do
  describe "#referral_share_text" do
    let(:setting) { Setting.instance }

    context "テンプレートが設定されている場合" do
      before do
        setting.update!(referral_share_template: "%{circle_name}へ。LINE: %{line_url} / 登録: %{signup_url}")
      end

      it "プレースホルダが値で置換される" do
        result = setting.referral_share_text(
          circle_name: "テストサークル",
          signup_url: "https://example.com/signup/abc",
          line_url: "https://line.me/R/ti/p/@example"
        )
        expect(result).to eq "テストサークルへ。LINE: https://line.me/R/ti/p/@example / 登録: https://example.com/signup/abc"
      end
    end

    context "テンプレートが空の場合" do
      before do
        setting.update!(referral_share_template: "")
      end

      it "空文字を返す" do
        result = setting.referral_share_text(
          circle_name: "テストサークル",
          signup_url: "https://example.com/signup/abc",
          line_url: "https://line.me/R/ti/p/@example"
        )
        expect(result).to eq ""
      end
    end

    context "テンプレートにプレースホルダが含まれない場合" do
      before do
        setting.update!(referral_share_template: "固定文言です")
      end

      it "そのまま返す" do
        result = setting.referral_share_text(
          circle_name: "テストサークル",
          signup_url: "https://example.com/signup/abc",
          line_url: "https://line.me/R/ti/p/@example"
        )
        expect(result).to eq "固定文言です"
      end
    end
  end

  describe "デフォルトテンプレート" do
    it "新規作成時にデフォルト文言が入る" do
      Setting.delete_all
      setting = Setting.instance
      expect(setting.referral_share_template).to eq Setting::DEFAULT_REFERRAL_SHARE_TEMPLATE
    end
  end
end
