class DropOldForumTables < ActiveRecord::Migration
  def change
    drop_table :forums
    drop_table :forum_threads
    drop_table :forum_posts
  end
end
