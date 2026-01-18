class EventAnnouncement < ApplicationRecord
  belongs_to :event
  belongs_to :announcement
end
