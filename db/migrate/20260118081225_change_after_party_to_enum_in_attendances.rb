class ChangeAfterPartyToEnumInAttendances < ActiveRecord::Migration[8.1]
  def change
    remove_column :attendances, :after_party, :boolean
    add_column :attendances, :after_party, :string, default: "undecided", null: false
  end
end
