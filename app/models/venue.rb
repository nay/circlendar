class Venue < ApplicationRecord
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true
end
