class AddConfirmationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_token, :string
    add_index :users, :confirmation_token, unique: true
  end
end
