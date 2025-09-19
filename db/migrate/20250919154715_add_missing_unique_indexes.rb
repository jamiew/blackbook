class AddMissingUniqueIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add unique index for favorites (user_id, object_id, object_type)
    # Note: There's already an index on object_id and object_type, but we need a unique composite with user_id
    add_index :favorites, [:user_id, :object_id, :object_type],
              unique: true,
              name: 'index_favorites_on_user_and_object'

    # Add unique index for likes (user_id, object_id, object_type)
    add_index :likes, [:user_id, :object_id, :object_type],
              unique: true,
              name: 'index_likes_on_user_and_object'

    # Add unique index for visualizations name
    add_index :visualizations, :name,
              unique: true,
              name: 'index_visualizations_on_name'

    # Note: Users table already has indexes on login, email, and iphone_uniquekey
    # but they're not marked as unique. Let's check if we can safely make them unique.

    # First, let's remove the non-unique indexes and add unique ones
    # Only do this if there are no duplicate values

    reversible do |dir|
      dir.up do
        # Check for duplicates before adding unique constraints
        duplicate_logins = execute("SELECT login, COUNT(*) FROM users GROUP BY login HAVING COUNT(*) > 1")
        duplicate_emails = execute("SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1")

        if duplicate_logins.count == 0
          remove_index :users, :login if index_exists?(:users, :login)
          add_index :users, :login, unique: true
        else
          say "Warning: Found duplicate logins, skipping unique index on users.login"
        end

        if duplicate_emails.count == 0
          remove_index :users, :email if index_exists?(:users, :email)
          add_index :users, :email, unique: true
        else
          say "Warning: Found duplicate emails, skipping unique index on users.email"
        end
      end

      dir.down do
        # When rolling back, restore non-unique indexes if they were removed
        if index_exists?(:users, :login, unique: true)
          remove_index :users, :login
          add_index :users, :login
        end

        if index_exists?(:users, :email, unique: true)
          remove_index :users, :email
          add_index :users, :email
        end
      end
    end
  end
end