class CreateAnnouncementDeliveryResults < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_delivery_results do |t|
      t.references :announcement_delivery, null: false, foreign_key: true
      t.string :resend_id, null: false
      t.string :address, null: false
      t.string :event
      t.timestamps
    end
    add_index :announcement_delivery_results, :resend_id, unique: true
  end
end
