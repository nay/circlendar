class CreateUserMailAddresses < ActiveRecord::Migration[8.1]
  def up
    create_table :user_mail_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address, null: false
      t.string :confirmation_token
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :user_mail_addresses, :address, unique: true
    add_index :user_mail_addresses, :confirmation_token, unique: true

    execute <<-SQL.squish
      INSERT INTO user_mail_addresses (user_id, address, confirmation_token, confirmed_at, created_at, updated_at)
      SELECT id, email_address, confirmation_token, confirmed_at, created_at, updated_at
      FROM users
    SQL

    change_column_null :users, :email_address, true
  end

  def down
    change_column_null :users, :email_address, false
    drop_table :user_mail_addresses
  end
end
