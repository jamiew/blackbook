class ConvertToUtf8mb4 < ActiveRecord::Migration[8.1]
  # utf8mb3 cannot store 4-byte characters, so emoji and some CJK have always
  # been silently rejected, and MySQL 8.4 deprecates the charset outright.
  #
  # utf8mb4_unicode_ci matches the collation compose.yaml and docs/deployment.md
  # give the database. Every table must share one collation or joins on string
  # columns fail with "illegal mix of collations".
  COLLATION = "utf8mb4_unicode_ci".freeze

  APP_TABLES = %w[favorites likes notifications tags users visualizations].freeze
  RAILS_TABLES = %w[schema_migrations ar_internal_metadata].freeze

  def up
    # ConvertTablesToInnodb left schema_migrations behind on MyISAM. Its unique
    # key on version varchar(255) is 1020 bytes under utf8mb4, over MyISAM's
    # 1000-byte index limit, so it has to move to InnoDB before the convert.
    execute "ALTER TABLE `schema_migrations` ENGINE=InnoDB"

    execute "ALTER DATABASE `#{current_database}` CHARACTER SET utf8mb4 COLLATE #{COLLATION}"

    (APP_TABLES + RAILS_TABLES).each do |table|
      execute "ALTER TABLE `#{table}` CONVERT TO CHARACTER SET utf8mb4 COLLATE #{COLLATION}"
    end
  end

  # Deliberately one-way. Converting back does not fail on 4-byte characters,
  # it silently mangles them: a stored 🎨 (F0 9F 8E A8) comes back as
  # C3 B0 C5 B8 C5 BD C2 A8, each byte reread as Latin-1 and re-encoded. MySQL
  # raises nothing, so a rollback would quietly destroy data. Verified on
  # MySQL 8.4. To get back to a pre-migration database, reload it with
  # script/resync-beta.sh instead.
  def down
    raise ActiveRecord::IrreversibleMigration,
          "Rolling back to utf8mb3 silently corrupts 4-byte characters. " \
          "Reload the database with script/resync-beta.sh instead."
  end

  private

  def current_database
    connection.current_database
  end
end
