class Attendance < ApplicationRecord
  belongs_to :event
  belongs_to :player

  enum :status, {
    attending: "attending",
    not_attending: "not_attending",
    undecided: "undecided"
  }, default: :undecided

  enum :after_party, {
    attending: "attending",
    not_attending: "not_attending",
    undecided: "undecided"
  }, default: :undecided, prefix: true

  validates :event, presence: true
  validates :player, presence: true
  validates :player_id, uniqueness: {
    scope: :event_id,
    message: ->(object, data) { "はすでにこの#{Event.model_name.human}について回答しています" }
  }
end
