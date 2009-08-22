class AddAdminUser < ActiveRecord::Migration
  def self.up
    say "adding default admin user"
    user = User.new(:login => 'admin',
      :email => 'admin@example.com',
      :password => 'changeme',
      :password_confirmation => 'changeme'
    )
    user.admin = true
    user.save!
  end

  def self.down
    begin
      User.find_by_login('admin').destroy
    rescue
      say "could not destroy 'admin' user: #{$!}"
    end
  end
end
