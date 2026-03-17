class AddLineSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :line_channel_id, :string
    add_column :settings, :line_channel_secret, :string
  end
end
