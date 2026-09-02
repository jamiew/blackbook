namespace :tags do
  def find_tags_with_missing_data
    bad = []
    Tag.find_each do |tag|
      print '.'
      $stdout.flush
      bad << tag if tag.data.blank?
    end
    bad
  end

  desc "Find tags that have missing data"
  task find_missing_data: :environment do
    bad = find_tags_with_missing_data
    puts "Found #{bad.length} tags with missing data: #{bad.map(&:id).join(', ')}"
  end

  desc "Delete tags with missing data (destructive, requires CONFIRM_DELETE)"
  task delete_missing_data: :environment do
    bad = find_tags_with_missing_data
    total = Tag.count

    # "Missing data" is decided by reading each GML file off disk. An unmounted
    # or wrongly symlinked data/ makes every tag look empty, so a large
    # proportion means check the mount, not delete the archive.
    if total.positive? && bad.length > total / 2
      abort "\nRefusing: #{bad.length} of #{total} tags look empty. That is a broken " \
            "data/ mount, not missing data. Run `rake data:validate` first."
    end

    unless ENV["CONFIRM_DELETE"] == "yes-i-have-a-backup"
      abort "\nRefusing: this permanently destroys #{bad.length} tags.\n" \
            "Take a backup (script/backup-production.sh), then re-run with:\n  " \
            "CONFIRM_DELETE=yes-i-have-a-backup rake tags:delete_missing_data"
    end

    puts "Deleting #{bad.length} bad-tags..."
    bad.each { |t| puts t.destroy }
    puts "Done"
  end
end
