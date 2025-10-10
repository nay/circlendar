class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :type
      t.references :user, null: true, foreign_key: true
      t.string :name
      t.string :organization_name
      t.string :rank
      t.references :attendance, null: true
      t.text :description

      t.timestamps
    end
  end
end
