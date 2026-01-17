class AnnouncementTemplate < ApplicationRecord
  PLACEHOLDERS = {
    "日付" => "{{日付}}",
    "会場" => "{{会場}}",
    "住所" => "{{住所}}",
    "アクセス" => "{{アクセス}}",
    "開始時刻" => "{{開始時刻}}",
    "終了時刻" => "{{終了時刻}}",
    "備考" => "{{備考}}"
  }.freeze

  validates :subject, presence: true
  validates :body, presence: true

  before_save :ensure_single_default

  scope :default_template, -> { find_by(default: true) }

  def has_placeholders?
    PLACEHOLDERS.values.any? { |placeholder| subject.include?(placeholder) || body.include?(placeholder) }
  end

  def self.fill_placeholders(text, event)
    return text unless event

    result = text.dup
    result.gsub!("{{日付}}", I18n.l(event.date, format: :long))
    result.gsub!("{{会場}}", event.venue.name)
    result.gsub!("{{住所}}", event.venue.address.to_s)
    result.gsub!("{{アクセス}}", event.venue.access_info.to_s)
    result.gsub!("{{開始時刻}}", event.start_time.strftime("%H:%M"))
    result.gsub!("{{終了時刻}}", event.end_time.strftime("%H:%M"))
    result.gsub!("{{備考}}", event.notes.to_s)
    result
  end

  private

  def ensure_single_default
    if default? && default_changed?
      self.class.where.not(id: id).update_all(default: false)
    end
  end
end
