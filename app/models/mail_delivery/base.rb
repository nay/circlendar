class MailDelivery::Base < ApplicationRecord
  self.table_name = "mail_deliveries"

  enum :status, { pending: "pending", requested: "requested", failed: "failed" }

  validates :address, presence: true
  validates :status, presence: true

  scope :on_date, ->(date) { where(requested_at: date.all_day) }
end
