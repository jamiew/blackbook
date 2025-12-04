class ConvertTablesToInnodb < ActiveRecord::Migration[8.1]
  def up
    # Convert all MyISAM tables to InnoDB for transaction support
    %w[comments favorites likes notifications tags users visualizations].each do |table|
      execute "ALTER TABLE #{table} ENGINE=InnoDB"
    end

    # Remove duplicate indexes created by earlier migrations
    remove_index :favorites, name: "index_on_object_id_and_object_type" if index_exists?(:favorites, name: "index_on_object_id_and_object_type")
    remove_index :favorites, name: "index_favorites_on_user_and_object" if index_exists?(:favorites, name: "index_favorites_on_user_and_object")
    remove_index :likes, name: "index_likes_on_user_and_object" if index_exists?(:likes, name: "index_likes_on_user_and_object")
    remove_index :visualizations, name: "index_visualizations_on_name" if index_exists?(:visualizations, name: "index_visualizations_on_name")
  end

  def down
    # Convert back to MyISAM (not recommended)
    %w[comments favorites likes notifications tags users visualizations].each do |table|
      execute "ALTER TABLE #{table} ENGINE=MyISAM"
    end
  end
end
