class ChangeEventTimeFieldsToSchedule < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :schedule, :string
    remove_column :events, :start_time, :time
    remove_column :events, :end_time, :time
  end
end
