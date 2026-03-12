class AnnouncementDeliveryResult < ApplicationRecord
  RESEND_EVENTS = %i[delivered bounced complained delivery_delayed].freeze

  belongs_to :announcement_delivery

  enum :event, RESEND_EVENTS.index_with(&:to_s)

  validates :resend_id, presence: true, uniqueness: true
  validates :address, presence: true
  validates :event, presence: true
end
