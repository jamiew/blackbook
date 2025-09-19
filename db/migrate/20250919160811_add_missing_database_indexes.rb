class AddMissingDatabaseIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add unique composite index for favorites table to prevent duplicate favorites
    # This enforces uniqueness at the database level for user_id + object_id + object_type
    add_index :favorites, [:user_id, :object_id, :object_type],
              unique: true,
              name: 'index_favorites_unique_on_user_and_object',
              if_not_exists: true

    # Add unique composite index for likes table to prevent duplicate likes
    # This enforces uniqueness at the database level for user_id + object_id + object_type
    add_index :likes, [:user_id, :object_id, :object_type],
              unique: true,
              name: 'index_likes_unique_on_user_and_object',
              if_not_exists: true

    # Add unique index for visualization names to prevent duplicate names
    add_index :visualizations, :name,
              unique: true,
              name: 'index_visualizations_unique_on_name',
              if_not_exists: true

    # Note: The users table already has indexes on login and email columns,
    # but they are not marked as unique. We're not adding unique constraints
    # here because the existing data contains duplicates (likely spam accounts)
    # that need to be cleaned up first before unique constraints can be added.
    #
    # To check for duplicates, run:
    # User.group(:login).having('COUNT(*) > 1').pluck(:login)
    # User.group(:email).having('COUNT(*) > 1').pluck(:email)
  end
end