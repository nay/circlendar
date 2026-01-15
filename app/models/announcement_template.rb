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

  private

  def ensure_single_default
    if default? && default_changed?
      self.class.where.not(id: id).update_all(default: false)
    end
  end
end
