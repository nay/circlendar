class Venue < ApplicationRecord
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true
  validates :short_name, presence: true
  validates :announcement_summary, presence: true
  validates :announcement_detail, presence: true
end
