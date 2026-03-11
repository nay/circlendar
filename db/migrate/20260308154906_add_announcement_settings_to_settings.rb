class AddAnnouncementSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :announcement_batch_size, :integer, default: 10, null: false
    add_column :settings, :announcement_daily_quota_threshold, :integer, default: 70, null: false
    add_column :settings, :announcement_retry_interval_hours, :integer, default: 2, null: false
  end
end
