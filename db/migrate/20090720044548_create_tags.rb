class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.integer :user_id
      t.string :title
      t.string :slug
      t.text :description
      t.integer :comment_count
      t.integer :likes_count

      t.timestamps
    end
  end

  def self.down
    drop_table :tags
  end
end
