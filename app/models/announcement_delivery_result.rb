class AnnouncementDeliveryResult < ApplicationRecord
  RESEND_EVENTS = %i[delivered bounced complained delivery_delayed].freeze

  belongs_to :announcement_delivery

  enum :event, { requested: "requested", **RESEND_EVENTS.index_with(&:to_s) }

  validates :resend_id, presence: true, uniqueness: true
  validates :address, presence: true
  validates :event, presence: true

  def self.update_event(resend_id:, event:)
    non_overwritable = %w[bounced complained]
    non_overwritable << "delivered" unless non_overwritable.include?(event)

    where(resend_id: resend_id)
      .where.not(event: non_overwritable)
      .update_all(event: event, updated_at: Time.current)
  end
end
