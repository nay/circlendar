class RenameAnnouncementsBccAddressesToRecipientAddresses < ActiveRecord::Migration[8.1]
  def change
    rename_column :announcements, :bcc_addresses, :recipient_addresses
  end
end
