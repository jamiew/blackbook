#
# Blackbook deployment
#

# Stand on the shoulders of giants
# `gem install capistrano-extensions cap-recipes`
require 'bundler/capistrano'
require 'capistrano/ext/multistage'
require 'cap_recipes/tasks/passenger'
#require 'cap_recipes/tasks/memcache'
#require 'cap_recipes/tasks/thinking_sphinx'

set :stages, %w(staging production)
set :default_stage, "production"
set :application, "blackbook"

# Server-specific information is stored in /config/deploy/#{stage}.rb

set :scm, :git
set :branch, ENV['BRANCH'] || 'master'
set :repository, "git@github.com:jamiew/#{application}.git"
set :deploy_via, :remote_cache
set :scm_verbose, true
#set :git_enable_submodules, 1
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

# Hooks
after "deploy:update_code", "deploy:create_symlinks"
after "deploy", "deploy:cleanup"
#after "bundle:install", "deploy:migrate"
before "deploy:migrate", "memcached:flush_if_pending_migrations"


#	Recipes
namespace :deploy do
  desc "Link database.yml & other shared settings"
  task :create_symlinks do
    run <<-CMD
      ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
      ln -nfs #{shared_path}/config/settings.yml #{release_path}/config/settings.yml &&
      ln -nfs #{shared_path}/config/memcached.yml #{release_path}/config/memcached.yml &&
      mkdir -p #{release_path}/public/ &&
      ln -nfs #{shared_path}/public/system #{release_path}/public/system
    CMD
  end

end


# Gem mgmnt
namespace :gems do
  desc "Install gems via 'rake gems:install'"
  task :install, :roles => :app do
    run "cd #{current_path} && #{sudo if use_sudo} RAILS_ENV=#{stage} rake gems:install"
  end
end


# Load production database into development
# Snippet modded from http://push.cx/2007/capistrano-task-to-load-production-data
namespace :sync do
  desc "Load production data into development database"
  task :db, :roles => :db, :only => { :primary => true } do
    database = YAML::load_file('config/database.yml')
    filename = "dump.#{Time.now.strftime '%Y-%m-%d_%H:%M:%S'}.sql.gz"
    # on_rollback { delete "/tmp/#{filename}" }

    # Run a dump & download from remote
    # run "mysqldump -u #{database['production']['username']} --password=#{database['production']['password']} #{database['production']['database']} > /tmp/#{filename}" do |channel, stream, data|
    ignores = "--ignore-table=#{database['production']['database']}.sessions"
    run "mysqldump -u #{database['production']['username']} --password=#{database['production']['password']} #{ignores} #{database['production']['database']} | gzip > /tmp/#{filename}"
    get "/tmp/#{filename}", filename

    # Load the dump
    # exec "mysql -u #{database['development']['username']} #{password} #{database['development']['database']} < #{filename}; rm -f #{filename}"
    puts "Loading #{filename} => #{database['development']['database']} ..."
    #TODO: drop & re-create the database -- causes newer migrations to fail sometimes otherwise, lingering new tables...
    system("gunzip -c #{filename} | mysql -u '#{database['development']['username']}' '#{database['development']['database']}' && rm -f #{filename}")
  end

  desc "rsync some prod image files"
  task :files, :roles => :web, :only => { :primary => true } do
    system("rsync -avz #{user}@#{domain}:#{shared_path}/public/ public/")
  end

  desc "Sync production db & files"
  task :all do
    sync::db
    sync::files
  end
end

# TODO: adapt this code in the future; I liek it. It needs loading, though, which is not DB agnostic
# namespace :db do
#   desc 'Dumps the production database to db/production_data.sql on the remote server'
#   task :remote_db_dump, :roles => :db, :only => { :primary => true } do
#     run "cd #{deploy_to}/#{current_dir} && " +
#       "rake RAILS_ENV=#{rails_env} db:database_dump --trace"
#   end
#
#   desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
#   task :remote_db_download, :roles => :db, :only => { :primary => true } do
#     execute_on_servers(options) do |servers|
#       self.sessions[servers.first].sftp.connect do |tsftp|
#         tsftp.download!("#{deploy_to}/#{current_dir}/db/production_data.sql", "db/production_data.sql")
#       end
#     end
#   end
#
#   desc 'Cleans up data dump file'
#   task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do
#     execute_on_servers(options) do |servers|
#       self.sessions[servers.first].sftp.connect do |tsftp|
#         tsftp.remove! "#{deploy_to}/#{current_dir}/db/production_data.sql"
#       end
#     end
#   end
#
#   desc 'Dumps, downloads and then cleans up the production data dump'
#   task :remote_db_runner do
#     remote_db_dump
#     remote_db_download
#     remote_db_cleanup
#   end
# end

namespace :memcached do
  desc "Flush memcached"
  task :flush, :roles => [:app] do
    run("cd #{current_release} && RAILS_ENV=#{rails_env} rake memcached:flush")
  end

  desc "Flush memcached if there are any pending migrations (installs hook, run before db:migrate)"
  # Depends on a local 'rake:pending_migrations' task... see lib/tasks/pending_migrations.rake
  task :flush_if_pending_migrations, :roles => [:app] do
    output = capture("cd #{current_release} && RAILS_ENV=#{rails_env} rake db:pending_migration_count")
    count = /(\d+) pending migrations/.match(output)
    if count[0] && count[0].to_i > 0
      puts "#{count[0].to_i} migrations will be run! Installing memcached:flush hook"
      after "deploy:migrate", "memcached:flush"
    end
  end
end
