set :rails_env, "production"

#############################################################
#	Servers
#############################################################

# set :user, 'oooooobook'
# set :use_sudo, false
# role :web, '000000book.com'
# role :app, '000000book.com'
# role :db, '000000book.com', :primary => true

set :user, 'jamie'
set :use_sudo, false
role :web, 'rickrolldb.com'
role :app, 'rickrolldb.com'
role :db, 'rickrolldb.com', :primary => true

set (:deploy_to) { "/home/jamie/blackbook2" }