namespace :tempt1 do
  desc 'Attach recovered TEMPT1 images, repair truncated GML, import unpublished tags.'
  task import: :environment do
    require Rails.root.join('lib/tempt1_import') # lib/ is not autoloaded
    report = Tempt1Import.new(dry_run: ENV['DRY_RUN'] == 'true').run
    report.print
    exit 1 if report.failed.any?
  end

  desc 'Report what the import would do, without writing anything'
  task verify: :environment do
    require Rails.root.join('lib/tempt1_import')
    Tempt1Import.new(dry_run: true).run.print
  end
end
