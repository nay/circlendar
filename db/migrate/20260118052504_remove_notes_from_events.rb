class RemoveNotesFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :notes, :text
  end
end
