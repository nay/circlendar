class RenameAnnouncementSentAtToDeliveryStartedAtAndAddDeliveryFinishedAt < ActiveRecord::Migration[8.1]
  def change
    rename_column :announcements, :sent_at, :delivery_started_at
    add_column :announcements, :delivery_finished_at, :datetime
  end
end
