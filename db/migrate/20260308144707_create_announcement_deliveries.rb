class CreateAnnouncementDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_deliveries do |t|
      t.references :announcement, null: false, foreign_key: true
      t.text :addresses, null: false, default: "[]"
      t.text :failed_addresses, null: false, default: "[]"
      t.string :status, null: false, default: "pending"
      t.datetime :next_run_at
      t.datetime :requested_at
      t.text :resend_ids, default: "[]"
      t.text :error_message

      t.timestamps
    end

    add_index :announcement_deliveries, :status
    add_index :announcement_deliveries, :next_run_at
  end
end
