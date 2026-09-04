class AddViewsCountToTags < ActiveRecord::Migration[8.1]
  # Counted when a tag's page, file or player payload is loaded. Indexed so
  # the front page's Popular set can sort 76,000 rows by it.
  def change
    add_column :tags, :views_count, :integer, default: 0, null: false
    add_index :tags, :views_count
  end
end
