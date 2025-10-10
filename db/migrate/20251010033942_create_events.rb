class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :venue, null: false, foreign_key: true
      t.date :date
      t.time :start_time
      t.time :end_time
      t.text :notes

      t.timestamps
    end
  end
end
