require "rails_helper"

RSpec.describe Event, type: :model do
  describe ".headline" do
    let(:venue_a) do
      Venue.create!(name: "三田分室", short_name: "三田", announcement_summary: "概要A", announcement_detail: "詳細A")
    end
    let(:venue_b) do
      Venue.create!(name: "勤労福祉会館", short_name: "勤福", announcement_summary: "概要B", announcement_detail: "詳細B")
    end

    it "イベントが1件の場合、日付と会場をセットで返す" do
      event = Event.create!(venue: venue_a, date: Date.new(2026, 3, 21), schedule: "10:00-12:00")
      expect(Event.headline([ event ])).to eq "3/21 (土)三田"
    end

    it "同じ会場の複数イベントの場合、日付と会場をセットにして読点で繋ぐ" do
      event1 = Event.create!(venue: venue_a, date: Date.new(2026, 3, 21), schedule: "10:00-12:00")
      event2 = Event.create!(venue: venue_a, date: Date.new(2026, 4, 18), schedule: "10:00-12:00")
      expect(Event.headline([ event1, event2 ])).to eq "3/21 (土)三田、4/18 (土)三田"
    end

    it "異なる会場の複数イベントの場合、日付と会場をセットにして読点で繋ぐ" do
      event1 = Event.create!(venue: venue_a, date: Date.new(2026, 3, 21), schedule: "10:00-12:00")
      event2 = Event.create!(venue: venue_b, date: Date.new(2026, 4, 18), schedule: "10:00-12:00")
      expect(Event.headline([ event1, event2 ])).to eq "3/21 (土)三田、4/18 (土)勤福"
    end

    it "日付順にソートされる" do
      event1 = Event.create!(venue: venue_b, date: Date.new(2026, 4, 18), schedule: "10:00-12:00")
      event2 = Event.create!(venue: venue_a, date: Date.new(2026, 3, 21), schedule: "10:00-12:00")
      expect(Event.headline([ event1, event2 ])).to eq "3/21 (土)三田、4/18 (土)勤福"
    end

    it "空の場合は空文字を返す" do
      expect(Event.headline([])).to eq ""
    end
  end
end
