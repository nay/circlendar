class AddAnnouncementTemplateToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    add_reference :announcements, :announcement_template, null: true, foreign_key: true
  end
end
