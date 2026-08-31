namespace :active_storage do
  desc "Attach existing Paperclip files to Active Storage. Idempotent and resumable."
  task backfill: :environment do
    require Rails.root.join('lib/active_storage_backfill') # lib/ is not autoloaded
    dry_run = ENV['DRY_RUN'] == 'true'
    puts "DRY RUN, nothing will be written" if dry_run

    report = ActiveStorageBackfill.new(dry_run: dry_run).run
    report.print

    # A non-zero exit means "do not proceed to deleting the Paperclip files".
    exit 1 if report.missing.any?
  end

  desc "Report what backfill would do, without writing anything"
  task verify: :environment do
    require Rails.root.join('lib/active_storage_backfill')
    ActiveStorageBackfill.new(dry_run: true).run.print
  end
end
