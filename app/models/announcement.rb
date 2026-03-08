class Announcement < ApplicationRecord
  has_many :event_announcements, dependent: :destroy
  has_many :events, through: :event_announcements
  has_many :deliveries, class_name: "AnnouncementDelivery", dependent: :destroy

  belongs_to :template, class_name: "AnnouncementTemplate", foreign_key: "announcement_template_id", optional: true
  belongs_to :sender, class_name: "User", foreign_key: "sent_by", optional: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  validates :subject, presence: true
  validates :body, presence: true

  def recipient_user_ids=(user_ids)
    self.recipient_addresses = UserMailAddress.where(user_id: user_ids).pluck(:address)
  end

  def sent?
    sent_at.present?
  end

  def apply_template
    return unless template

    self.subject = AnnouncementTemplate.fill_placeholders(template.subject, events)
    self.body = AnnouncementTemplate.fill_placeholders(template.body, events)
  end

  def create_deliveries!
    ordered_addresses = UserMailAddress.where(address: recipient_addresses)
                                      .joins(:user).merge(User.ordered)
                                      .pluck(:address)
    ordered_addresses += recipient_addresses - ordered_addresses

    deliveries.create!(addresses: ordered_addresses)
  end
end
