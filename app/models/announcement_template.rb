class AnnouncementTemplate < ApplicationRecord
  PLACEHOLDERS = {
    "練習会サマリー" => "{{練習会サマリー}}",
    "日付" => "{{日付}}",
    "会場名" => "{{会場名}}",
    "会場URL" => "{{会場URL}}",
    "開始時刻" => "{{開始時刻}}",
    "終了時刻" => "{{終了時刻}}"
  }.freeze

  validates :subject, presence: true
  validates :body, presence: true
  validate :validate_placeholders

  before_save :ensure_single_default

  scope :default_template, -> { find_by(default: true) }

  def has_placeholders?
    PLACEHOLDERS.values.any? { |placeholder| subject.include?(placeholder) || body.include?(placeholder) }
  end

  def self.fill_placeholders(text, events)
    events = Array(events).compact
    return text if events.empty?

    result = text.dup

    # 練習会サマリー（複数イベント対応）
    # 桁がバラバラな場合のみパディング
    pad_month = events.map { |e| e.date.month >= 10 }.uniq.size > 1
    pad_day = events.map { |e| e.date.day >= 10 }.uniq.size > 1

    summary_lines = events.map do |event|
      date_str = format_date_zenkaku(event.date, pad_month:, pad_day:)
      venue_summary = event.venue.announcement_summary.presence || event.venue.name
      "#{date_str}　＠#{venue_summary}"
    end
    result.gsub!("{{練習会サマリー}}", summary_lines.join("\n"))

    # 単一イベント用プレースホルダー（最初のイベントを使用）
    event = events.first
    result.gsub!("{{日付}}", I18n.l(event.date, format: :long))
    result.gsub!("{{会場名}}", event.venue.name)
    result.gsub!("{{会場URL}}", event.venue.url.to_s)
    result.gsub!("{{開始時刻}}", event.start_time.strftime("%H:%M"))
    result.gsub!("{{終了時刻}}", event.end_time.strftime("%H:%M"))
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

  private

  def validate_placeholders
    validate_placeholders_in(:subject, subject)
    validate_placeholders_in(:body, body)
  end

  def validate_placeholders_in(attribute, text)
    return if text.blank?

    if malformed?(text)
      errors.add(attribute, "の練習会情報の埋め込み形式が不正です")
      return
    end

    text.scan(/\{\{([^}]+)\}\}/).each do |match|
      name = match[0]
      unless PLACEHOLDERS.key?(name)
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
