require "rails_helper"

RSpec.describe Event, type: :model do
  describe ".headline" do
    let(:venue_a) { create(:venue, short_name: "三田") }
    let(:venue_b) { create(:venue, short_name: "勤福") }

    it "イベントが1件の場合、日付と会場をセットで返す" do
      event = create(:event, venue: venue_a, date: Date.new(2026, 3, 21))
      expect(Event.headline([ event ])).to eq "3/21 (土)三田"
    end

    it "同じ会場の複数イベントの場合、日付と会場をセットにして読点で繋ぐ" do
      event1 = create(:event, venue: venue_a, date: Date.new(2026, 3, 21))
      event2 = create(:event, venue: venue_a, date: Date.new(2026, 4, 18))
      expect(Event.headline([ event1, event2 ])).to eq "3/21 (土)三田、4/18 (土)三田"
    end

    it "異なる会場の複数イベントの場合、日付と会場をセットにして読点で繋ぐ" do
      event1 = create(:event, venue: venue_a, date: Date.new(2026, 3, 21))
      event2 = create(:event, venue: venue_b, date: Date.new(2026, 4, 18))
      expect(Event.headline([ event1, event2 ])).to eq "3/21 (土)三田、4/18 (土)勤福"
    end

    it "日付順にソートされる" do
      event1 = create(:event, venue: venue_b, date: Date.new(2026, 4, 18))
      event2 = create(:event, venue: venue_a, date: Date.new(2026, 3, 21))
      expect(Event.headline([ event1, event2 ])).to eq "3/21 (土)三田、4/18 (土)勤福"
    end

    it "空の場合は空文字を返す" do
      expect(Event.headline([])).to eq ""
    end
  end
end
