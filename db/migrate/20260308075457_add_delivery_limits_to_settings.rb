class AddDeliveryLimitsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :daily_mail_delivery_limit, :integer, default: 100, null: false
    add_column :settings, :daily_announcement_delivery_limit, :integer, default: 70, null: false
  end
end
