class AddNoteToAnnouncementDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :announcement_deliveries, :note, :text
  end
end
