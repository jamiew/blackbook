 ############################################################
#   __     __              __     __                 __      #
#  |  |--.|  |.---.-.----.|  |--.|  |--.-----.-----.|  |--.  #
#  |  _  ||  ||  _  |  __||    < |  _  |  _  |  _  ||    <   #
#  |_____||__||___._|____||__|__||_____|_____|_____||__|__|  #
#                                                            #
 ############################################################

# Specifies gem version of Rails to use when vendor/rails is not present
# Dreamhost only has Rails 2.2.2, so we're freezing Rails to 2.3.2 -- 2.3.3 has weird regressions
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Requires that must be outside initializer, since they are used during the initializer
# gem 'rack-cache'
# require 'rack/cache'

Rails::Initializer.run do |config|

  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Actually used by the app
  config.gem 'haml'
  config.gem 'config_reader', :version => '0.0.6'
  config.gem 'RedCloth'
  config.gem 'authlogic', :version => '2.0.9'
  config.gem 'nokogiri'
  config.gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
  config.gem 'unicode' # needed for i76-has_slug
  config.gem "i76-has_slug", :lib => 'has_slug', :source => 'http://gems.github.com'
  config.gem "configatron", :version => "2.2.2"
  config.gem "will_paginate", :version => "2.3.12"
  config.gem "htmlentities"    

  # Testing
  config.gem "rspec", :lib => false, :version => ">= 1.2.0" 
  config.gem "rspec-rails", :lib => false, :version => ">= 1.2.0"   
  config.gem "thoughtbot-factory_girl", :lib => false, :source => "http://gems.github.com"
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  config.frameworks -= [ :active_resource ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  
  # Use Rack::Cache middleware
  # config.middleware.use Rack::Cache,
  #   :verbose => true,
  #   :metastore   => 'memcached://localhost:11211/blackbook-rack-cache-meta',
  #   :entitystore => 'memcached://localhost:11211/blackbook-rack-cache-body'
    
  
end

# require everything in /lib
Dir.glob(RAILS_ROOT+"/lib/*.rb").each { |file| require file }

