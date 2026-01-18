class Event < ApplicationRecord
  belongs_to :venue
  has_many :attendances, dependent: :destroy
  has_many :players, through: :attendances
  has_many :members, -> { where(type: "Member") }, through: :attendances, source: :player
  has_many :event_announcements, dependent: :destroy
  has_many :announcements, through: :event_announcements

  enum :status, { draft: "draft", published: "published" }, default: :draft

  validates :date, presence: true
  validates :schedule, presence: true

  scope :upcoming, -> { where("date >= ?", Date.today) }
  scope :past, -> { where("date < ?", Date.today) }

  def upcoming?
    date >= Date.today
  end

  def headline
    Event.headline([ self ])
  end

  # 複数イベントのヘッドライン生成（お知らせ件名用）
  def self.headline(events)
    events = Array(events).compact.sort_by(&:date)
    return "" if events.empty?

    dates_str = events.map(&:formatted_date_short).join("＆")
    venues_str = events.map(&:venue).uniq.map(&:short_name).join("・")
    "#{dates_str} #{venues_str}"
  end

  def formatted_date_short
    wday = %w[日 月 火 水 木 金 土][date.wday]
    "#{date.month}/#{date.day} (#{wday})"
  end
end
