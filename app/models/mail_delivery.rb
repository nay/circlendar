class MailDelivery < ApplicationRecord
  enum :status, { pending: "pending", requested: "requested", failed: "failed" }

  validates :address, presence: true
  validates :status, presence: true

  scope :on_date, ->(date) { where(requested_at: date.in_time_zone("Asia/Tokyo").all_day) }
end
