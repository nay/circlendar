class Announcement < ApplicationRecord
  has_many :event_announcements, dependent: :destroy
  has_many :events, through: :event_announcements
  has_many :deliveries, class_name: "MailDelivery::Announcement", dependent: :nullify

  belongs_to :template, class_name: "AnnouncementTemplate", foreign_key: "announcement_template_id", optional: true
  belongs_to :sender, class_name: "User", foreign_key: "sent_by", optional: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  validates :subject, presence: true
  validates :body, presence: true

  def bcc_user_ids=(user_ids)
    self.bcc_addresses = UserMailAddress.where(user_id: user_ids).pluck(:address)
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
    daily_limit = Setting.instance.daily_announcement_delivery_limit
    now = Time.current

    records = bcc_addresses.each_with_index.map do |address, i|
      day_offset = i / daily_limit
      scheduled = if day_offset.zero?
        nil
      else
        (Date.tomorrow + (day_offset - 1).days).in_time_zone("Asia/Tokyo").change(hour: 9)
      end

      {
        type: "MailDelivery::Announcement",
        announcement_id: id,
        address: address,
        status: "pending",
        scheduled_at: scheduled,
        created_at: now,
        updated_at: now
      }
    end

    MailDelivery::Announcement.insert_all!(records) if records.any?
  end

  def process_deliveries!
    from = "#{Setting.instance.circle_name} <#{ENV.fetch('MAILER_FROM', 'noreply@example.com')}>"

    deliveries.pending.find_each do |delivery|
      delivery.request_send!(from: from, subject: subject, body: body, reply_to: to_address)
      sleep(0.5)
    end
  end
end
