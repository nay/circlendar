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

    recent = self.class.recent_sent_count
    if recent >= setting.announcement_daily_quota_threshold
      update!(next_run_at: setting.announcement_retry_interval_hours.hours.from_now,
              note: "配信済数#{recent}件が#{Setting.human_attribute_name(:announcement_daily_quota_threshold)}（#{setting.announcement_daily_quota_threshold}件）以上のため待機")
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
    update!(next_run_at: Setting.instance.announcement_retry_interval_hours.hours.from_now, note: "バッチ送信で429レートリミット、待機")
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
      message = "#{batch.size}件送信、残り#{remaining.size}件を分割して新規delivery作成"
      message += "（直前のAPIレスポンスから得られた現在の実クォータ（#{quota}件）が#{Setting.human_attribute_name(:announcement_daily_quota_threshold)}（#{setting.announcement_daily_quota_threshold}件）以上のため待機）" if next_run
      transaction do
        AnnouncementDelivery.create!(announcement: announcement, addresses: remaining, next_run_at: next_run)
        update!(addresses: batch, resend_ids: ids, status: :requested, requested_at: Time.current, note: message)
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
      save_progress!(sent_addrs, sent_ids, new_failed, unsent,
                     next_run_at: Setting.instance.announcement_retry_interval_hours.hours.from_now,
                     note: build_retry_note(sent_addrs, new_failed, unsent: unsent, rate_limited: true))
      return
    rescue StandardError
      new_failed << address
    end

    save_progress!(sent_addrs, sent_ids, new_failed, remaining,
                   note: build_retry_note(sent_addrs, new_failed, unsent: remaining))
  end

  def save_progress!(sent_addrs, sent_ids, new_failed, unsent, next_run_at: nil, note: nil)
    if sent_addrs.any?
      transaction do
        if unsent.any?
          AnnouncementDelivery.create!(announcement: announcement, addresses: unsent, next_run_at: next_run_at)
        end
        update!(addresses: sent_addrs, resend_ids: sent_ids, failed_addresses: new_failed, status: :requested, requested_at: Time.current, note: note)
      end
    elsif unsent.any?
      update!(failed_addresses: new_failed, next_run_at: next_run_at, note: note)
    else
      update!(failed_addresses: new_failed, status: :failed, error_message: "all addresses failed", note: note)
    end
  end

  def build_retry_note(sent_addrs, new_failed, unsent: [], rate_limited: false)
    newly_failed_count = new_failed.size - failed_addresses.size
    message = "バッチ送信エラーのため個別送信にフォールバック、#{sent_addrs.size}件成功、#{newly_failed_count}件失敗"
    if rate_limited
      message += "、429レートリミットにより#{unsent.size}件を分割して新規delivery作成、待機"
    elsif unsent.any?
      message += "、残り#{unsent.size}件を分割して新規delivery作成"
    end
    message
  end
end
