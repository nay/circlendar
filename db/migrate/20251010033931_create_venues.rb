class CreateVenues < ActiveRecord::Migration[8.0]
  def change
    create_table :venues do |t|
      t.string :name
      t.string :address
      t.string :url
      t.text :access_info
      t.text :notes

      t.timestamps
    end
  end
end
