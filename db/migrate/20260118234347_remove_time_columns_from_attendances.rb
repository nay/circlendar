class RemoveTimeColumnsFromAttendances < ActiveRecord::Migration[8.1]
  def change
    remove_column :attendances, :arrival_time, :time
    remove_column :attendances, :departure_time, :time
  end
end
