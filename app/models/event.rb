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

  def display_name
    "#{formatted_date_short} #{venue.short_name}"
  end

  def formatted_date_short
    wday = %w[日 月 火 水 木 金 土][date.wday]
    "#{date.month}/#{date.day} (#{wday})"
  end
end
