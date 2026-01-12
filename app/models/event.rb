class Event < ApplicationRecord
  belongs_to :venue
  has_many :attendances, dependent: :destroy
  has_many :players, through: :attendances
  has_many :members, -> { where(type: "Member") }, through: :attendances, source: :player
  has_many :announcements, dependent: :nullify

  enum :status, { draft: "draft", published: "published" }, default: :draft

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  scope :upcoming, -> { where("date >= ?", Date.today) }
  scope :past, -> { where("date < ?", Date.today) }
end
