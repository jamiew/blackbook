# rubocop:disable Lint/RedundantRequireStatement
# Set is autoloaded on Ruby 3.2+, but this task is meant to also run on the
# Ruby 2.5 production checkout, where it is not.
require "set"
# rubocop:enable Lint/RedundantRequireStatement
require "fileutils"
# Paperclip is gone, so the attachment section below reads its path shapes from
# the backfill rather than restating them. Required by path, and holding only
# lambdas and a Struct, so it still loads on the legacy checkout.
require File.expand_path("../active_storage_backfill", __dir__)

# Read-only integrity audit of the GML corpus, the uploaded images and the
# database. Writes nothing except a report under tmp/data-validate/.
#
# Deliberately avoids Rails-8-only APIs so it runs unchanged on the legacy
# Rails 4.2 production checkout. Copy it to the server and run it BEFORE the
# upgrade migrations, then again after, and diff the two reports:
#
#   scp lib/tasks/data.rake prod:~/blackbook/lib/tasks/
#   scp lib/active_storage_backfill.rb prod:~/blackbook/lib/
#   RAILS_ENV=production bundle exec rake data:validate > before.txt
#
# Exits non-zero when it finds something that will abort a pending migration,
# so it can be used as a deploy preflight.
namespace :data do
  def conn
    ActiveRecord::Base.connection
  end

  def table?(name)
    if conn.respond_to?(:data_source_exists?)
      conn.data_source_exists?(name)
    else
      conn.table_exists?(name)
    end
  end

  def count(sql)
    conn.select_value(sql).to_i
  end

  # True when the named migration is on disk but not yet in schema_migrations.
  # Reads the table directly; the migration API differs across the Rails
  # versions this task runs on.
  def pending_migration?(name)
    file = Rails.root.glob("db/migrate/*_#{name}.rb").first
    return false if file.nil?

    version = File.basename(file).split("_").first
    count("SELECT COUNT(*) FROM schema_migrations WHERE version = #{conn.quote(version)}").zero?
  end

  def heading(title)
    puts "\n== #{title} #{'=' * [0, 60 - title.length].max}"
  end

  def sample(list, limit = 25)
    shown = list.to_a.sort.first(limit)
    more = list.size - shown.length
    text = shown.join(", ")
    more.positive? ? "#{text} ... and #{more} more" : text
  end

  desc "Read-only audit: missing GML files, orphans, broken images, migration blockers"
  task validate: :environment do
    blockers = []
    warnings = []
    report_dir = Rails.root.join("tmp/data-validate")
    FileUtils.mkdir_p(report_dir)

    puts "blackbook data validation"
    puts "env=#{Rails.env} database=#{conn.respond_to?(:current_database) ? conn.current_database : 'unknown'}"
    puts "reports -> #{report_dir}"

    heading "row counts"
    %w[tags users favorites likes visualizations notifications comments].each do |t|
      puts "  #{t.ljust(16)} #{table?(t) ? count("SELECT COUNT(*) FROM #{t}") : '(no such table)'}"
    end

    heading "GML files on disk vs tag rows"
    data_dir = Rails.root.join("data").to_s
    puts "  dir: #{data_dir}"
    if File.directory?(data_dir)
      disk_ids = Set.new
      odd_names = []
      empty_files = []
      suspect_files = []

      Dir.glob(File.join(data_dir, "*.gml")).each do |path|
        base = File.basename(path, ".gml")
        base.match?(/\A\d+\z/) ? disk_ids << base.to_i : odd_names << path

        if File.empty?(path)
          empty_files << path
        else
          # Case-insensitive: real captures open with `<GML spec="0.1b">`, only the
          # rspec fixtures use `<gml>`. binread keeps this safe on files with
          # invalid UTF-8 byte sequences.
          suspect_files << path unless /<gml/i.match?(File.binread(path, 400).to_s)
        end
      end

      db_ids = Set.new(conn.select_values("SELECT id FROM tags").map(&:to_i))
      missing = db_ids - disk_ids
      orphans = disk_ids - db_ids

      puts "  .gml files:              #{disk_ids.size}"
      puts "  tag rows:                #{db_ids.size}"
      puts "  tags with NO file:       #{missing.size}"
      puts "    #{sample(missing)}" if missing.any?
      puts "  files with NO tag row:   #{orphans.size}"
      puts "    #{sample(orphans)}" if orphans.any?
      puts "  zero-byte files:         #{empty_files.size}"
      puts "  no <gml> root element:   #{suspect_files.size}"
      puts "  non-numeric filenames:   #{odd_names.size}"

      File.write(report_dir.join("tags-missing-gml-file.txt"), missing.to_a.sort.join("\n"))
      File.write(report_dir.join("orphan-gml-files.txt"), orphans.to_a.sort.join("\n"))
      File.write(report_dir.join("empty-gml-files.txt"), empty_files.sort.join("\n"))
      File.write(report_dir.join("suspect-gml-files.txt"), suspect_files.sort.join("\n"))

      warnings << "#{missing.size} tags have no GML file on disk" if missing.any?
      warnings << "#{empty_files.size} GML files are zero bytes" if empty_files.any?
      if suspect_files.any?
        # Seen locally: an old serialization bug wrote a `<hash>` root element
        # instead of `<gml>`. Structure is intact, the wrapper is wrong.
        warnings << "#{suspect_files.size} GML files have no <gml> root element"
      end

      # A near-total miss almost always means the data volume is not mounted,
      # not that the corpus is gone. Say so loudly before anyone "cleans up".
      if db_ids.any? && missing.size > db_ids.size / 2
        blockers << "Over half of all tags have no GML file. Check that #{data_dir} " \
                    "is mounted and pointing at the real corpus before trusting this report."
      end
    else
      blockers << "#{data_dir} does not exist or is not a directory"
      puts "  MISSING"
    end

    heading "attachment files on disk"
    ActiveStorageBackfill::ATTACHMENTS.each do |spec|
      model_name = spec[:model]
      att = spec[:name].to_s
      col = spec[:column].to_s
      klass = model_name.safe_constantize
      next puts "  #{model_name}: model not loadable, skipped" unless klass

      checked = 0
      broken = []
      klass.where("#{col} IS NOT NULL AND #{col} != ''").find_each do |record|
        checked += 1
        file = record.read_attribute(col)
        broken << record.id if spec[:paths].call(record, file).none? { |path| Rails.root.join(path).file? }
      end

      puts "  #{"#{model_name}##{att}:".ljust(24)} #{checked} with a filename, #{broken.size} missing from disk"
      puts "    #{sample(broken)}" if broken.any?
      File.write(report_dir.join("broken-#{model_name.downcase}-#{att}.txt"), broken.sort.join("\n"))
      warnings << "#{broken.size} #{model_name}##{att} files missing from disk" if broken.any?
    end

    heading "orphaned references"
    checks = [
      ["tags -> missing user",
       "SELECT COUNT(*) FROM tags t LEFT JOIN users u ON u.id = t.user_id
        WHERE t.user_id IS NOT NULL AND u.id IS NULL"],
      ["favorites -> missing user",
       "SELECT COUNT(*) FROM favorites f LEFT JOIN users u ON u.id = f.user_id
        WHERE f.user_id IS NOT NULL AND u.id IS NULL"],
      ["favorites -> missing tag",
       "SELECT COUNT(*) FROM favorites f LEFT JOIN tags t ON t.id = f.object_id
        WHERE f.object_type = 'Tag' AND t.id IS NULL"],
      ["favorites -> unknown object_type",
       "SELECT COUNT(*) FROM favorites WHERE object_type NOT IN ('Tag','Visualization')"],
      ["likes -> missing user",
       "SELECT COUNT(*) FROM likes l LEFT JOIN users u ON u.id = l.user_id
        WHERE l.user_id IS NOT NULL AND u.id IS NULL"],
      ["likes -> missing tag",
       "SELECT COUNT(*) FROM likes l LEFT JOIN tags t ON t.id = l.object_id
        WHERE l.object_type = 'Tag' AND t.id IS NULL"],
      ["notifications -> missing user",
       "SELECT COUNT(*) FROM notifications n LEFT JOIN users u ON u.id = n.user_id
        WHERE n.user_id IS NOT NULL AND u.id IS NULL"]
    ]
    checks.each do |label, sql|
      table = sql[/FROM (\w+)/, 1]
      next puts "  #{label}: (no #{table} table)" unless table?(table)

      n = count(sql)
      puts "  #{"#{label}:".ljust(34)} #{n}"
      warnings << "#{n} orphaned rows: #{label}" if n.positive?
    end

    heading "pending migration blockers"
    # users.login / users.email: mirror the migration's own duplicate check
    # exactly, because that query is what decides whether it skips the index.
    %w[login email].each do |col|
      n = count("SELECT COUNT(*) FROM (SELECT #{col} FROM users GROUP BY #{col} HAVING COUNT(*) > 1) x")
      note = n.positive? ? " (migration will SKIP this index)" : ""
      puts "  duplicate users.#{"#{col}:".ljust(22)} #{n}#{note}"
      warnings << "#{n} duplicate users.#{col} values, unique index will be skipped" if n.positive?
    end

    # favorites / likes / visualizations have no duplicate guard. MySQL treats
    # NULLs as distinct in a unique index, so only non-NULL dupes actually abort.
    unique_targets = [
      ["favorites", "user_id, object_id, object_type",
       "user_id IS NOT NULL AND object_id IS NOT NULL AND object_type IS NOT NULL"],
      ["likes", "user_id, object_id, object_type",
       "user_id IS NOT NULL AND object_id IS NOT NULL AND object_type IS NOT NULL"],
      ["visualizations", "name", "name IS NOT NULL"]
    ]
    unique_targets.each do |table, cols, not_null|
      next puts "  #{table}: (no such table)" unless table?(table)

      n = count("SELECT COUNT(*) FROM (SELECT #{cols} FROM #{table}
                 WHERE #{not_null} GROUP BY #{cols} HAVING COUNT(*) > 1) x")
      flag = n.positive? ? " <-- ABORTS MIGRATION" : ""
      puts "  duplicate #{"#{table} (#{cols}):".ljust(44)} #{n}#{flag}"
      blockers << "#{n} duplicate #{table} (#{cols}) rows will abort the unique index migration" if n.positive?
    end

    # convert_tables_to_innodb ALTERs comments unconditionally, with no if_exists.
    # Only a problem while it is still pending: afterwards, comments is meant to
    # be gone.
    if !table?("comments") && pending_migration?("convert_tables_to_innodb")
      blockers << "convert_tables_to_innodb runs ALTER TABLE comments but that table is gone"
    end

    heading "irreversible data loss in the pending migrations"
    if table?("comments")
      n = count("SELECT COUNT(*) FROM comments")
      puts "  drop_comments_table will permanently delete #{n} comments"
      warnings << "#{n} comments will be permanently deleted by drop_comments_table" if n.positive?
    end
    if table?("tags") && conn.columns("tags").any? { |c| c.name == "ipfs_hash" }
      n = count("SELECT COUNT(*) FROM tags WHERE ipfs_hash IS NOT NULL")
      puts "  remove_ipfs_from_tags will drop tags.ipfs_hash, #{n} rows have a value"
      warnings << "#{n} tags.ipfs_hash values will be dropped" if n.positive?
    end

    heading "storage engines"
    rows = conn.select_all(
      "SELECT TABLE_NAME, ENGINE, TABLE_ROWS, ROUND(DATA_LENGTH/1024/1024) AS data_mb
       FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() ORDER BY DATA_LENGTH DESC"
    ).to_a
    rows.each do |r|
      puts "  #{r['TABLE_NAME'].to_s.ljust(18)} #{r['ENGINE'].to_s.ljust(8)} " \
           "#{r['TABLE_ROWS'].to_s.rjust(9)} rows #{r['data_mb'].to_s.rjust(6)} MB"
    end
    myisam = rows.select { |r| r["ENGINE"] == "MyISAM" }
    if myisam.any?
      puts "  #{myisam.length} MyISAM tables. convert_tables_to_innodb rewrites each one,"
      puts "  needing roughly 2x the largest table in free disk and locking it meanwhile."
    end

    heading "verdict"
    if warnings.any?
      puts "WARNINGS (#{warnings.length}), safe to proceed but know what you are losing:"
      warnings.each { |w| puts "  - #{w}" }
    end
    if blockers.any?
      puts "\nBLOCKERS (#{blockers.length}), fix before migrating:"
      blockers.each { |b| puts "  - #{b}" }
      abort "\nFAILED: #{blockers.length} blocker(s). Full lists in #{report_dir}"
    end
    puts "\nNo blockers. Full lists in #{report_dir}"
  end
end
