class CreateEventAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :event_announcements do |t|
      t.references :event, null: false, foreign_key: true
      t.references :announcement, null: false, foreign_key: true

      t.timestamps
    end

    add_index :event_announcements, [ :event_id, :announcement_id ], unique: true

    remove_reference :announcements, :event, foreign_key: true
  end
end
