class Event < ApplicationRecord
  belongs_to :venue
  has_many :attendances, dependent: :destroy
  has_many :players, through: :attendances
  has_many :members, -> { where(type: 'Member') }, through: :attendances, source: :player
  has_many :announcements, dependent: :nullify

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
end
