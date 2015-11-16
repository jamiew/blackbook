class CreateFavorites < ActiveRecord::Migration
  def self.up
    create_table :favorites do |t|
      t.integer :user_id
      t.string :object_type
      t.integer :object_id


      t.timestamps
    end
  end

  def self.down
    drop_table :favorites
  end
end
