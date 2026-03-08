require "rails_helper"

RSpec.describe Announcement, type: :model do
  before do
    Setting.instance.update!(daily_announcement_delivery_limit: 3)
  end

  let(:announcement) do
    Announcement.create!(
      subject: "テスト",
      body: "本文",
      to_address: "admin@example.com",
      recipient_addresses: addresses
    )
  end

  describe "#create_deliveries!" do
    context "上限以下の場合" do
      let(:addresses) { [ "a@example.com", "b@example.com" ] }

      it "全件 scheduled_at なしで作成される" do
        announcement.create_deliveries!
        deliveries = announcement.deliveries.reload

        expect(deliveries.size).to eq(2)
        expect(deliveries.map(&:scheduled_at)).to all(be_nil)
        expect(deliveries.map(&:status)).to all(eq("pending"))
      end
    end

    context "上限を超える場合" do
      let(:addresses) { (1..5).map { |i| "user#{i}@example.com" } }

      it "上限を超えた分は翌日以降に scheduled_at が設定される" do
        announcement.create_deliveries!
        deliveries = announcement.deliveries.reload.order(:id)

        immediate = deliveries.select { |d| d.scheduled_at.nil? }
        scheduled = deliveries.reject { |d| d.scheduled_at.nil? }

        expect(immediate.size).to eq(3)
        expect(scheduled.size).to eq(2)
        expect(scheduled.first.scheduled_at.in_time_zone("Asia/Tokyo").hour).to eq(9)
      end
    end

    context "上限の2倍を超える場合" do
      let(:addresses) { (1..8).map { |i| "user#{i}@example.com" } }

      it "3日に分散される" do
        announcement.create_deliveries!
        deliveries = announcement.deliveries.reload.order(:id)

        dates = deliveries.map { |d| d.scheduled_at&.in_time_zone("Asia/Tokyo")&.to_date }.uniq
        expect(dates.size).to eq(3) # nil（即時）, 明日, 明後日
      end
    end
  end

  describe "#process_deliveries!" do
    context "当日分のみの場合" do
      let(:addresses) { [ "a@example.com", "b@example.com" ] }

      it "Batch API で一括送信する" do
        announcement.create_deliveries!
        announcement.process_deliveries!

        deliveries = announcement.deliveries.reload
        expect(deliveries.map(&:status)).to all(eq("requested"))
        expect(deliveries.map(&:resend_id)).to all(start_with("fake_"))
      end
    end

    context "当日分と予約分が混在する場合" do
      let(:addresses) { (1..5).map { |i| "user#{i}@example.com" } }

      it "当日分は Batch API、予約分は個別送信する" do
        announcement.create_deliveries!
        announcement.process_deliveries!

        deliveries = announcement.deliveries.reload.order(:id)
        immediate = deliveries.select { |d| d.scheduled_at.nil? }
        scheduled = deliveries.reject { |d| d.scheduled_at.nil? }

        expect(immediate.map(&:status)).to all(eq("requested"))
        expect(immediate.map(&:resend_id)).to all(start_with("fake_"))
        expect(scheduled.map(&:status)).to all(eq("requested"))
        expect(scheduled.map(&:resend_id)).to all(start_with("fake_"))
      end
    end
  end
end
