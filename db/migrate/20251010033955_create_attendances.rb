class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :event, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :status
      t.time :arrival_time
      t.time :departure_time
      t.boolean :after_party
      t.text :message

      t.timestamps
    end
  end
end
