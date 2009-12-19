set :rails_env, "production"

#############################################################
#	Servers
#############################################################

# set :user, 'oooooobook'
# set :use_sudo, false
# role :web, '000000book.com'
# role :app, '000000book.com'
# role :db, '000000book.com', :primary => true

set :user, 'blackbook'
set :use_sudo, false
set :deploy_to, "/home/blackbook/blackbook"

role :web, '000000book.com', :primary => true
role :app, '000000book.com'
role :db, '000000book.com', :primary => true

# set (:deploy_to) { "/home/blackbook/blackbook" }
