class CreateVisualizations < ActiveRecord::Migration
  def self.up
    create_table :visualizations do |t|
      t.integer :user_id
      t.string :name
      t.string :slug
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :visualizations
  end
end
