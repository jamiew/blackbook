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

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Ripped from GemTools -- support libs we want; require them as gem dependencies
  # config.gem 'capistrano'
  # config.gem 'capistrano-ext'

  # Actually used by the app
  config.gem 'haml'
  config.gem 'config_reader', :version => '0.0.6'
  config.gem 'RedCloth'
  config.gem 'expose_model'
  config.gem 'authlogic', :version => '2.0.9'
  config.gem 'nokogiri'
  config.gem 'jackdempsey-acts_as_commentable', :lib => 'acts_as_commentable', :source => "http://gems.github.com"
  config.gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
  config.gem "i76-has_slug", :lib => 'has_slug', :source => 'http://gems.github.com'
  config.gem "configatron", :version => ">= 2.2.2"
  config.gem "mislav-will_paginate", :lib => "will_paginate", :version => "~>2.3.6"
  # config.gem 'giraffesoft-is_taggable', :lib => 'is_taggable', :source => 'http://gems.github.com'
  config.gem "htmlentities"
  # Spawn installed as a plugin -- not available as a gem

  # Plugins I still need to get used to
  # config.gem 'justinfrench-formtastic', :lib => 'formtastic', :source => 'http://gems.github.com'
  # config.gem 'rubymood-jintastic', :lib => 'jintastic', :source => 'http://gems.github.com'

  # Testing
  config.gem "rspec", :lib => false, :version => ">= 1.2.0" 
  config.gem "rspec-rails", :lib => false, :version => ">= 1.2.0"   
  config.gem "thoughtbot-factory_girl", :lib => false, :source => "http://gems.github.com"
  config.gem 'spicycode-rcov', :lib => false, :source => 'http://gems.github.com'
  # config.gem "aslakhellesoy-cucumber", :lib => false, :source => 'http://gems.github.com'
  # config.gem "jscruggs-metric_fu", :lib => false, :source => 'http://gems.github.com'
  # config.gem 'timcharper-spork', :lib => false, :source => 'http://gems.github.com'

  
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
  
end

# require everything in /lib
Dir.glob(RAILS_ROOT+"/lib/*.rb").each { |file| require file }

