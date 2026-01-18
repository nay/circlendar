class AnnouncementTemplate < ApplicationRecord
  SUBJECT_PLACEHOLDERS = {
    "練習会ヘッドライン" => "{{練習会ヘッドライン}}"
  }.freeze

  BODY_PLACEHOLDERS = {
    "練習会サマリー" => "{{練習会サマリー}}",
    "会場案内" => "{{会場案内}}",
    "ダッシュボードURL" => "{{ダッシュボードURL}}",
    "サインアップURL" => "{{サインアップURL}}"
  }.freeze

  ALL_PLACEHOLDERS = SUBJECT_PLACEHOLDERS.merge(BODY_PLACEHOLDERS).freeze

  validates :subject, presence: true
  validates :body, presence: true
  validate :validate_placeholders

  before_save :ensure_single_default

  scope :default_template, -> { find_by(default: true) }

  def has_placeholders?
    ALL_PLACEHOLDERS.values.any? { |placeholder| subject.include?(placeholder) || body.include?(placeholder) }
  end

  def has_signup_url_placeholder?
    body&.include?("{{サインアップURL}}")
  end

  def self.fill_placeholders(text, events)
    events = Array(events).compact.sort_by(&:date)
    return text if events.empty?

    result = text.dup

    # 練習会ヘッドライン（サブジェクト用）
    result.gsub!("{{練習会ヘッドライン}}", Event.headline(events))

    # 練習会サマリー（複数イベント対応）
    # 桁がバラバラな場合のみパディング
    pad_month = events.map { |e| e.date.month >= 10 }.uniq.size > 1
    pad_day = events.map { |e| e.date.day >= 10 }.uniq.size > 1

    summary_lines = events.map do |event|
      date_str = format_date_zenkaku(event.date, pad_month:, pad_day:)
      venue_summary = event.venue.announcement_summary.presence || event.venue.name
      prefix = "#{date_str}　＠"
      indent = "　" * (display_width(prefix) / 2)
      "#{prefix}#{venue_summary}\n#{indent}#{event.schedule}"
    end
    result.gsub!("{{練習会サマリー}}", summary_lines.join("\n"))

    # 会場案内（ユニークな会場ごとにannouncement_detailを空行区切りで）
    venue_details = events.map(&:venue).uniq.filter_map do |venue|
      venue.announcement_detail.presence
    end
    result.gsub!("{{会場案内}}", venue_details.join("\n\n"))

    # ダッシュボードURL
    dashboard_url = Rails.application.routes.url_helpers.dashboard_url
    result.gsub!("{{ダッシュボードURL}}", dashboard_url)

    # サインアップURL
    if result.include?("{{サインアップURL}}")
      signup_token = Setting.instance.signup_token
      raise "サインアップトークンが未発行です" if signup_token.blank?
      signup_url = Rails.application.routes.url_helpers.signup_url(token: signup_token)
      result.gsub!("{{サインアップURL}}", signup_url)
    end

    result
  end

  def self.format_date_zenkaku(date, pad_month: false, pad_day: false)
    month = date.month.to_s.tr("0-9", "０-９")
    day = date.day.to_s.tr("0-9", "０-９")
    wday = %w[日 月 火 水 木 金 土][date.wday]

    # 桁がバラバラな場合のみ全角スペースでパディング
    month = "　#{month}" if pad_month && date.month < 10
    day = "　#{day}" if pad_day && date.day < 10

    "#{month}月#{day}日(#{wday})"
  end

  def self.display_width(str)
    str.each_char.sum do |char|
      char.bytesize > 1 ? 2 : 1
    end
  end

  private

  def validate_placeholders
    validate_placeholders_in(:subject, subject, SUBJECT_PLACEHOLDERS)
    validate_placeholders_in(:body, body, BODY_PLACEHOLDERS)
  end

  def validate_placeholders_in(attribute, text, allowed_placeholders)
    return if text.blank?

    if malformed?(text)
      errors.add(attribute, "の練習会情報の埋め込み形式が不正です")
      return
    end

    text.scan(/\{\{([^}]+)\}\}/).each do |match|
      name = match[0]
      unless allowed_placeholders.key?(name)
        errors.add(attribute, "の{{#{name}}}は無効な埋め込み情報です")
      end
    end
  end

  def malformed?(text)
    open_count = text.scan("{{").count
    close_count = text.scan("}}").count
    return true if open_count != close_count

    depth = 0
    i = 0
    while i < text.length - 1
      if text[i, 2] == "{{"
        depth += 1
        return true if depth > 1
        i += 2
      elsif text[i, 2] == "}}"
        depth -= 1
        return true if depth < 0
        i += 2
      else
        i += 1
      end
    end

    depth != 0
  end

  def ensure_single_default
    if default? && default_changed?
      self.class.where.not(id: id).update_all(default: false)
    end
  end
end
