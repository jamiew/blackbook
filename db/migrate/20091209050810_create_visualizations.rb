class CreateVisualizations < ActiveRecord::Migration
  def self.up
    create_table :visualizations, force: true do |t|
      t.integer :user_id
      t.string :name
      t.string :slug
      t.string :website
      t.string :download
      t.string :version
      t.text :description
    end
  end

  def self.down
    drop_table :visualizations
  end
end
