class CreateLikes < ActiveRecord::Migration
  def self.up
    create_table :likes do |t|
      t.integer :object_id
      t.string :object_type
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :likes
  end
end
