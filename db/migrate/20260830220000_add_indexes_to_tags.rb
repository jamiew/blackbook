class AddIndexesToTags < ActiveRecord::Migration[8.1]
  # The tags table has carried no index but the primary key since 2009, so
  # every listing page has been a full scan plus a filesort over ~77k rows.
  # Measured locally at that row count: the newest-30 query on the front page
  # took 66ms, the applications dropdown 49ms, and page one of /data 65ms.
  def change
    # Every listing is ordered by this, and the front page and /data read
    # nothing else.
    add_index :tags, :created_at, name: 'index_tags_on_created_at'

    # A writer's own tags, sorted. The composite covers the WHERE and the
    # ORDER BY together so neither needs a sort.
    add_index :tags, [:user_id, :created_at], name: 'index_tags_on_user_id_and_created_at'

    # `?app=` filters on either column, and the applications dropdown reads
    # DISTINCT application on every request.
    add_index :tags, :application, name: 'index_tags_on_application'
    add_index :tags, :gml_application, name: 'index_tags_on_gml_application'

    # Drives the claimed/unclaimed/from_device scopes and the daily writer
    # count in the header.
    add_index :tags, :gml_uniquekey, name: 'index_tags_on_gml_uniquekey'
  end
end
