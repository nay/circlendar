class CreateAnnouncementTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :announcement_templates do |t|
      t.string :name
      t.text :subject
      t.text :body
      t.boolean :is_default

      t.timestamps
    end
  end
end
