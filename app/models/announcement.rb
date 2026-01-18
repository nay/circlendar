class Announcement < ApplicationRecord
  has_many :event_announcements, dependent: :destroy
  has_many :events, through: :event_announcements

  belongs_to :template, class_name: "AnnouncementTemplate", foreign_key: "announcement_template_id", optional: true
  belongs_to :sender, class_name: "User", foreign_key: "sent_by", optional: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  validates :subject, presence: true
  validates :body, presence: true

  def sent?
    sent_at.present?
  end

  def apply_template
    return unless template

    self.subject = AnnouncementTemplate.fill_placeholders(template.subject, events.first)
    self.body = AnnouncementTemplate.fill_placeholders(template.body, events.first)
  end
end
