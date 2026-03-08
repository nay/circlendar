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
    daily_limit = Setting.instance.daily_announcement_delivery_limit
    already_sent = MailDelivery::Announcement.requested.on_date(Time.current).count
    remaining_today = [ daily_limit - already_sent, 0 ].max
    now = Time.current

    ordered_addresses = UserMailAddress.where(address: recipient_addresses)
                                      .joins(:user).merge(User.ordered)
                                      .pluck(:address)
    ordered_addresses += recipient_addresses - ordered_addresses

    records = ordered_addresses.each_with_index.map do |address, i|
      scheduled = if i < remaining_today
        nil
      else
        day_offset = (i - remaining_today) / daily_limit
        (Date.tomorrow + day_offset.days).in_time_zone("Asia/Tokyo").change(hour: 9)
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
    client = Rails.application.config.resend_client_class.constantize
    pending = deliveries.pending.order(:id)
    immediate = pending.where(scheduled_at: nil).to_a
    scheduled = pending.where.not(scheduled_at: nil).to_a

    # 当日分: Batch API
    if immediate.any?
      params_array = immediate.map { |d| { from: from, to: [ d.address ], subject: subject, text: body, reply_to: to_address } }
      response = client.send_batch(params_array)
      now = Time.current
      immediate.zip(response[:data]).each do |delivery, result|
        delivery.update!(status: :requested, requested_at: now, resend_id: result[:id])
      end
    end

    # 予約分: 個別送信（batch後のレートリミット対策で sleep から開始）
    scheduled.each do |delivery|
      sleep(0.5)
      delivery.request_send!(from: from, subject: subject, body: body, reply_to: to_address)
    end
  end
end
