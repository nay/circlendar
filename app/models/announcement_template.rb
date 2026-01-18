class AnnouncementTemplate < ApplicationRecord
  PLACEHOLDERS = {
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

  def self.fill_placeholders(text, event)
    return text unless event

    result = text.dup
    result.gsub!("{{日付}}", I18n.l(event.date, format: :long))
    result.gsub!("{{会場名}}", event.venue.name)
    result.gsub!("{{会場URL}}", event.venue.url.to_s)
    result.gsub!("{{開始時刻}}", event.start_time.strftime("%H:%M"))
    result.gsub!("{{終了時刻}}", event.end_time.strftime("%H:%M"))
    result
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
