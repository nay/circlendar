require "rails_helper"

RSpec.describe AnnouncementTemplate, type: :model do
  describe "#valid?" do
    let(:template) { AnnouncementTemplate.new(subject:, body:) }
    let(:subject) { "練習会のお知らせ" }
    let(:body) { "{{日付}} {{会場}}" }

    context "有効な埋め込み情報がある場合" do
      it "検証が通る" do
        expect(template).to be_valid
      end
    end

    context "すべての埋め込み情報を使用した場合" do
      let(:body) { "{{日付}} {{会場}} {{住所}} {{アクセス}} {{開始時刻}} {{終了時刻}} {{備考}}" }

      it "検証が通る" do
        expect(template).to be_valid
      end
    end

    context "件名に無効な埋め込み情報がある場合" do
      let(:subject) { "{{date}}の練習会" }

      it "検証エラーとなる" do
        expect(template).not_to be_valid
        expect(template.errors[:subject]).to include("の{{date}}は無効な埋め込み情報です")
      end
    end

    context "本文に無効な埋め込み情報がある場合" do
      let(:body) { "{{unknown}}があります" }

      it "検証エラーとなる" do
        expect(template).not_to be_valid
        expect(template.errors[:body]).to include("の{{unknown}}は無効な埋め込み情報です")
      end
    end

    context "埋め込み情報が閉じられていない場合" do
      let(:body) { "{{日付 の練習会" }

      it "検証エラーとなる" do
        expect(template).not_to be_valid
        expect(template.errors[:body]).to include("の練習会情報の埋め込み形式が不正です")
      end
    end

    context "埋め込み情報の開始がない場合" do
      let(:body) { "日付}}の練習会" }

      it "検証エラーとなる" do
        expect(template).not_to be_valid
        expect(template.errors[:body]).to include("の練習会情報の埋め込み形式が不正です")
      end
    end

    context "埋め込み情報が入れ子になっている場合" do
      let(:body) { "{{日付{{会場}}}}の練習会" }

      it "検証エラーとなる" do
        expect(template).not_to be_valid
        expect(template.errors[:body]).to include("の練習会情報の埋め込み形式が不正です")
      end
    end

    context "埋め込み情報がない場合" do
      let(:subject) { "件名です" }
      let(:body) { "本文です" }

      it "検証が通る" do
        expect(template).to be_valid
      end
    end
  end
end
