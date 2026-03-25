class ChangeUserMailAddressForeignKeyOnAnnouncementDeliveryResults < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :announcement_delivery_results, :user_mail_addresses
    add_foreign_key :announcement_delivery_results, :user_mail_addresses, on_delete: :nullify
  end
end
