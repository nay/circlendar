class RestructureVenueColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :venues, :address, :string
    remove_column :venues, :access_info, :text
    remove_column :venues, :notes, :text
    add_column :venues, :announcement_summary, :text
    add_column :venues, :announcement_detail, :text
  end
end
