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
end
