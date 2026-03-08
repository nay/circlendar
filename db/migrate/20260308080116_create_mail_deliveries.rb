class CreateMailDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :mail_deliveries do |t|
      t.string :type, null: false
      t.references :announcement, null: true, foreign_key: { on_delete: :nullify }
      t.string :address, null: false
      t.string :status, null: false, default: "pending"
      t.string :kind
      t.datetime :scheduled_at
      t.datetime :requested_at
      t.string :resend_id
      t.text :error_message
      t.timestamps
    end

    add_index :mail_deliveries, :status
    add_index :mail_deliveries, :requested_at
  end
end
