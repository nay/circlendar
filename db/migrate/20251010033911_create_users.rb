class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :role
      t.boolean :receives_announcements, default: true

      t.timestamps
    end
  end
end
