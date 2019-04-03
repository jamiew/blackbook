class AddAdminUser < ActiveRecord::Migration
  def self.up
    say "adding default admin user"
    begin
      user = User.new(login: 'admin',
        email: 'admin@example.com',
        password: 'changeme',
        password_confirmation: 'changeme'
      )
      user.admin = true
      user.save!
    rescue
      say "could not create default admin user: #{$!}"
    end
  end

  def self.down
    begin
      User.find_by_login('admin').destroy
    rescue
      say "could not destroy 'admin' user: #{$!}"
    end
  end
end
