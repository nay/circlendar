class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :sent_by
      t.text :subject
      t.text :body
      t.string :to_address
      t.text :bcc_addresses, array: true, default: []
      t.datetime :sent_at

      t.timestamps
    end
  end
end
