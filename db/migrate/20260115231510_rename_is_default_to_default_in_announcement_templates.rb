class RenameIsDefaultToDefaultInAnnouncementTemplates < ActiveRecord::Migration[8.1]
  def change
    rename_column :announcement_templates, :is_default, :default
  end
end
