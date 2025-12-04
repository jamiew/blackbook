class DropCommentsTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :comments, if_exists: true
  end

  def down
    create_table :comments do |t|
      t.string :title, limit: 50, default: ""
      t.text :text
      t.references :commentable, polymorphic: true
      t.references :user
      t.string :ip_address
      t.datetime :hidden_at
      t.timestamps
    end

    add_index :comments, :commentable_type
    add_index :comments, :commentable_id
    add_index :comments, :user_id
  end
end
