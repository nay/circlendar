class AddShortNameToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :short_name, :string
  end
end
