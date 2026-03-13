class AnnouncementDelivery < ApplicationRecord
  class QuotaExceededError < StandardError; end

  belongs_to :announcement
  has_many :results, class_name: "AnnouncementDeliveryResult", dependent: :destroy

  enum :status, { pending: "pending", requested: "requested", failed: "failed" }

  validates :status, presence: true

  before_save :build_results, if: -> { status_changed? && requested? }
  after_save :finish_announcement_delivery

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
  rescue QuotaExceededError, Resend::Error::RateLimitExceededError
    # Stop processing - will retry on next invocation
  end

  def process!
    setting = Setting.instance

    recent = self.class.recent_sent_count
    raise QuotaExceededError if recent >= setting.announcement_daily_quota_threshold

    sendable = addresses - failed_addresses
    batch = sendable.first(setting.announcement_batch_size)
    remaining = sendable.drop(setting.announcement_batch_size)

    if batch.empty?
      update!(status: :failed, error_message: "送信可能なアドレスがありません")
      return
    end

    # Phase 1: API呼び出し — 失敗したら個別リトライ（まだ送信されていない）
    response = begin
      self.class.client.send_batch(build_params(batch))
    rescue Resend::Error::RateLimitExceededError
      raise
    rescue StandardError => e
      retry_individually!(batch, remaining, batch_error: e)
      return
    end

    # Phase 2: 後処理 — 送信済みなのでリトライ不可、最低限の状態を保存
    begin
      complete_batch!(batch, response, remaining)
    rescue StandardError => e
      handle_post_send_error!(batch, response, remaining, error: e)
    end
  end

  private

  def build_params(batch)
    batch.map do |address|
      { from: self.class.from, to: [ address ], subject: announcement.subject, text: announcement.body, reply_to: announcement.to_address }
    end
  end

  def complete_batch!(batch, response, remaining)
    ids = response[:data].map { |r| r[:id] }
    quota = Array(response[:headers]&.dig("x-resend-daily-quota")).first.to_i

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

  def retry_individually!(batch, remaining, batch_error: nil)
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
                     note: build_retry_note(sent_addrs, new_failed, unsent: unsent, rate_limited: true, batch_error: batch_error))
      raise
    rescue StandardError
      new_failed << address
    end

    save_progress!(sent_addrs, sent_ids, new_failed, remaining,
                   note: build_retry_note(sent_addrs, new_failed, unsent: remaining, batch_error: batch_error))
  end

  def save_progress!(sent_addrs, sent_ids, new_failed, unsent, note: nil)
    if sent_addrs.any?
      transaction do
        if unsent.any?
          AnnouncementDelivery.create!(announcement: announcement, addresses: unsent)
        end
        update!(addresses: sent_addrs, resend_ids: sent_ids, failed_addresses: new_failed, status: :requested, requested_at: Time.current, note: note)
      end
    elsif unsent.any?
      update!(failed_addresses: new_failed, note: note)
    else
      update!(failed_addresses: new_failed, status: :failed, error_message: "送信可能なアドレスがありません", note: note)
    end
  end

  def build_results
    return unless resend_ids.present?

    existing = results.map(&:resend_id).to_set
    mail_address_by_address = UserMailAddress.where(address: addresses).index_by(&:address)
    addresses.each_with_index do |address, i|
      next unless resend_ids[i]
      next if existing.include?(resend_ids[i])

      results.build(resend_id: resend_ids[i], address: address, event: :requested, user_mail_address: mail_address_by_address[address])
    end
  end

  def finish_announcement_delivery
    return if pending?
    return unless announcement.delivery_started_at?
    return if announcement.delivery_finished_at?
    return if announcement.deliveries.pending.exists?

    announcement.update!(delivery_finished_at: Time.current)
  end

  def handle_post_send_error!(batch, response, remaining, error:)
    ids = begin
      response[:data]&.map { |r| r[:id] }
    rescue StandardError
      []
    end
    note = "バッチ送信成功後の処理でエラー（#{error.class}: #{error.message}）"
    note += "、残り#{remaining.size}件を分割して新規delivery作成" if remaining.any?
    transaction do
      AnnouncementDelivery.create!(announcement: announcement, addresses: remaining) if remaining.any?
      update!(addresses: batch, resend_ids: ids, status: :requested, requested_at: Time.current, note: note)
    end
  end

  def build_retry_note(sent_addrs, new_failed, unsent: [], rate_limited: false, batch_error: nil)
    newly_failed_count = new_failed.size - failed_addresses.size
    error_detail = batch_error ? "（#{batch_error.class}: #{batch_error.message}）" : ""
    message = "バッチ送信エラー#{error_detail}のため個別送信にフォールバック、#{sent_addrs.size}件成功、#{newly_failed_count}件失敗"
    if rate_limited
      message += "、429レートリミットにより#{unsent.size}件を分割して新規delivery作成"
    elsif unsent.any?
      message += "、残り#{unsent.size}件を分割して新規delivery作成"
    end
    message
  end
end
