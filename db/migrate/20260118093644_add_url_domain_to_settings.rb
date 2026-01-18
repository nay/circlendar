class AddUrlDomainToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :url_domain, :string, default: "https://example.com", null: false
  end
end
