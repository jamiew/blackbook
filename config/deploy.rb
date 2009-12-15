#
# Blackbook deployment
#

# Stand on the shoulders of giants
# `sudo gem install capistrano-extensions cap-recipes`
require 'capistrano/ext/multistage'
require 'cap_recipes/tasks/passenger'
# require 'cap_recipes/tasks/memcache'
# require 'cap_recipes/tasks/thinking_sphinx'


# Application
set :stages, %w(staging production)
set :default_stage, "production"
set :application, "blackbook"

# Settings
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

# Server-specific information is stored in /config/deploy/#{stage}.rb

#	Git
set :scm, :git
set :branch, ENV['BRANCH'] || 'master'
# set :scm_user, 'deploy'
# set (:deploy_to) { "/home/oooooobook/000000book.com2/#{stage}" }
# set (:deploy_to) { "/home/jamie/blackbook2" }
set :repository, "git@github.com:jamiew/#{application}.git"
set :deploy_via, :remote_cache
set :scm_verbose, true
set :git_enable_submodules, 1


# Hooks
before "deploy", "gems:install"
# ...


#	Recipes
namespace :deploy do
  desc "This to do once we get the code up"
  task :after_update_code, :roles => :app, :except => { :no_release => true } do
    # run "cd #{release_path} && sudo gemtools install"
    # run "cd #{release_path} && RAILS_ENV=#{stage} ./script/runner Sass::Plugin.update_stylesheets"
    # run "cd #{release_path} && RAILS_ENV=#{stage} rake db:migrate"
  end

  task :after_symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{current_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/settings.yml #{current_path}/config/settings.yml"

    run "mkdir -p #{release_path}/public/"
    run "ln -nfs #{shared_path}/public/system #{current_path}/public/system"    

    # metric_fu -- creating dirs just to make sure
    # run "mkdir -p #{shared_path}/metric_fu"
    # run "rm -rf #{release_path}/tmp/metric_fu" # ln can't force-overwrite directories
    # run "ln -nfs #{shared_path}/metric_fu #{current_path}/tmp/metric_fu"
  end


  # desc "Symlink the upload directories"
  # task :before_symlink do
  #   run "mkdir -p #{shared_path}/uploads"
  #   run "ln -s #{shared_path}/uploads #{release_path}/public/uploads"
  # end
end


# Gem mgmnt
namespace :gems do
  desc "Install gems via 'rake gems:install'"
  task :install, :roles => :app do
    run "cd #{current_path} && #{sudo} RAILS_ENV=#{stage} rake gems:install"
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

    # run "mysqldump -u #{database['production']['username']} --password=#{database['production']['password']} #{database['production']['database']} > /tmp/#{filename}" do |channel, stream, data|
    ignores = "--ignore-table=#{database['production']['database']}.sessions"
    run "mysqldump -u #{database['production']['username']} --password=#{database['production']['password']} #{ignores} #{database['production']['database']} | gzip > /tmp/#{filename}"
    get "/tmp/#{filename}", filename

    # exec "mysql -u #{database['development']['username']} #{password} #{database['development']['database']} < #{filename}; rm -f #{filename}"
    # FIXME exec and run w/ localhost as host not working :\
    puts "Loading #{filename} => #{database['development']['database']} ..."
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
