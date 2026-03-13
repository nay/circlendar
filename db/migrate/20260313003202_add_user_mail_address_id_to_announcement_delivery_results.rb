class AddUserMailAddressIdToAnnouncementDeliveryResults < ActiveRecord::Migration[8.1]
  def change
    add_reference :announcement_delivery_results, :user_mail_address, foreign_key: true
  end
end
