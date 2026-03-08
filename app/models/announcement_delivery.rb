class AnnouncementDelivery < ApplicationRecord
  belongs_to :announcement

  enum :status, { pending: "pending", requested: "requested", failed: "failed" }

  validates :status, presence: true

  serialize :addresses, coder: JSON
  serialize :failed_addresses, coder: JSON
  serialize :resend_ids, coder: JSON

  scope :processable, -> {
    pending.where("next_run_at IS NULL OR next_run_at <= ?", Time.current)
  }

  def self.client
    Rails.application.config.resend_client_class.constantize
  end

  def self.from
    "#{Setting.instance.circle_name} <#{ENV.fetch('MAILER_FROM', 'noreply@example.com')}>"
  end

  def self.recent_sent_count
    requested
      .where("requested_at >= ?", 24.hours.ago)
      .sum("json_array_length(addresses::json) - json_array_length(failed_addresses::json)")
  end

  def self.process_queue!
    loop do
      delivery = processable.order(:id).lock("FOR UPDATE SKIP LOCKED").first
      break unless delivery
      delivery.process!
      sleep(0.5)
    end
  end

  def process!
    setting = Setting.instance

    if self.class.recent_sent_count >= setting.announcement_daily_quota_threshold
      update!(next_run_at: setting.announcement_retry_interval_hours.hours.from_now)
      return
    end

    sendable = addresses - failed_addresses
    batch = sendable.first(setting.announcement_batch_size)
    remaining = sendable.drop(setting.announcement_batch_size)

    if batch.empty?
      update!(status: :failed, error_message: "all addresses failed")
      return
    end

    response = self.class.client.send_batch(build_params(batch))
    complete_batch!(batch, response, remaining)
  rescue Resend::Error::RateLimitExceededError
    update!(next_run_at: Setting.instance.announcement_retry_interval_hours.hours.from_now)
  rescue StandardError
    retry_individually!(batch, remaining)
  end

  private

  def build_params(batch)
    batch.map do |address|
      { from: self.class.from, to: [ address ], subject: announcement.subject, text: announcement.body, reply_to: announcement.to_address }
    end
  end

  def complete_batch!(batch, response, remaining)
    ids = response[:data].map { |r| r[:id] }
    quota = response[:headers]&.dig("x-resend-daily-quota").to_i

    if remaining.any?
      setting = Setting.instance
      next_run = quota >= setting.announcement_daily_quota_threshold ? setting.announcement_retry_interval_hours.hours.from_now : nil
      transaction do
        AnnouncementDelivery.create!(announcement: announcement, addresses: remaining, next_run_at: next_run)
        update!(addresses: batch, resend_ids: ids, status: :requested, requested_at: Time.current)
      end
    else
      update!(addresses: batch, resend_ids: ids, status: :requested, requested_at: Time.current)
    end
  end

  def retry_individually!(batch, remaining)
    sent_addrs = []
    sent_ids = []
    new_failed = failed_addresses.dup

    batch.each do |address|
      sleep(0.5)
      response = self.class.client.send_batch(build_params([ address ]))
      sent_addrs << address
      sent_ids << response[:data].first[:id]
    rescue Resend::Error::RateLimitExceededError
      unsent = (batch - sent_addrs - new_failed) + remaining
      save_progress!(sent_addrs, sent_ids, new_failed, unsent, next_run_at: Setting.instance.announcement_retry_interval_hours.hours.from_now)
      return
    rescue StandardError
      new_failed << address
    end

    save_progress!(sent_addrs, sent_ids, new_failed, remaining)
  end

  def save_progress!(sent_addrs, sent_ids, new_failed, unsent, next_run_at: nil)
    if sent_addrs.any?
      transaction do
        if unsent.any?
          AnnouncementDelivery.create!(announcement: announcement, addresses: unsent, next_run_at: next_run_at)
        end
        update!(addresses: sent_addrs, resend_ids: sent_ids, failed_addresses: new_failed, status: :requested, requested_at: Time.current)
      end
    elsif unsent.any?
      update!(failed_addresses: new_failed, next_run_at: next_run_at)
    else
      update!(failed_addresses: new_failed, status: :failed, error_message: "all addresses failed")
    end
  end
end
