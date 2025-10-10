class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :circle_name

      t.timestamps
    end
  end
end
