class AddSignupTokenToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :signup_token, :string
  end
end
