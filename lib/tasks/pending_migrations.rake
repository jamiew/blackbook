namespace :db do
  desc "Output the number of pending migrations"
  task :pending_migration_count => :environment do
    size = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations.size
    puts "#{size} pending migrations"
  end
end

