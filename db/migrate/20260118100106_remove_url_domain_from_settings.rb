class RemoveUrlDomainFromSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :url_domain, :string
  end
end
