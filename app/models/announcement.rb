class Announcement < ApplicationRecord
  belongs_to :event, optional: true
  belongs_to :sender, class_name: "User", foreign_key: "sent_by", optional: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  validates :subject, presence: true
  validates :body, presence: true

  def sent?
    sent_at.present?
  end
end
