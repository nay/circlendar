class RemoveNameFromAnnouncementTemplates < ActiveRecord::Migration[8.1]
  def change
    remove_column :announcement_templates, :name, :string
  end
end
