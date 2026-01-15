class AnnouncementTemplate < ApplicationRecord
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
