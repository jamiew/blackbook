# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

config.cache_store = :mem_cache_store

# Don't care if the mailer can't send, and stash mails in ActionMailer::Base.deliveries (:test)
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :test

# Use bullet to auto-analyze easy DB optimizations
# http://github.com/flyerhzm/bullet
config.gem 'bullet'
config.after_initialize do
  Bullet.enable = false
  Bullet.alert = false # intense alert() notification action
  Bullet.bullet_logger = true # log/bullet.log
  Bullet.console = false #javascript console()
  Bullet.rails_logger = true # log/#{environment}.log
  Bullet.disable_browser_cache = true #...DOCME

  # Display growl notifications on Mac
  begin
    require 'ruby-growl'
    Bullet.growl = false
  rescue MissingSourceFile
    # STDERR.puts "$$ Bullet: could not initialize Growl; skipping..."
  end
end

# To use Oink log parsing we need to use hodel3000-style logging
# http://github.com/noahd1/oink
#require RAILS_ROOT+'/lib/hodel_3000_logger'
#config.logger = Hodel3000CompliantLogger.new(RAILS_ROOT+'/log/hodel_3000.log')
