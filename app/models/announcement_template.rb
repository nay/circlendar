class AnnouncementTemplate < ApplicationRecord
  validates :name, presence: true
  validates :subject, presence: true
  validates :body, presence: true
end
