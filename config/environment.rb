 ############################################################
#   __     __              __     __                 __      #
#  |  |--.|  |.---.-.----.|  |--.|  |--.-----.-----.|  |--.  #
#  |  _  ||  ||  _  |  __||    < |  _  |  _  |  _  ||    <   #
#  |_____||__||___._|____||__|__||_____|_____|_____||__|__|  #
#                                                            #
 ############################################################

RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Hack to make old rails work with new rubygems
if Gem::VERSION >= "1.3.6"
  module Rails
    class GemDependency
      def requirement
        r = super
        (r == Gem::Requirement.default) ? nil : r
      end
    end
  end
end

Rails::Initializer.run do |config|

  config.gem 'haml', :version => '3.0.12'
  config.gem 'config_reader', :version => '0.0.6'
  config.gem 'RedCloth', :version => '4.2.3'
  config.gem 'authlogic', :version => '2.0.9'
  config.gem 'nokogiri'
  config.gem 'paperclip', :version => '2.3.3'
  config.gem 'unicode', :version => '0.3.1' # required by has_slug
  config.gem 'has_slug', :version => '0.2.7'
  config.gem 'configatron', :version => '2.2.2'
  config.gem 'will_paginate', :version => '2.3.12'
  config.gem 'htmlentities', :version => '4.2.1'
  config.gem 'system_timer', :version => '1.0'

  # Rails configuration
  config.time_zone = 'UTC'
  config.frameworks -= [ :active_resource ]
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

end

# require everything in /lib
Dir.glob(RAILS_ROOT+"/lib/*.rb").each { |file| require file }

# We <3 Exceptions
ExceptionNotification::Notifier.exception_recipients = %w(jamie+blackbook@jamiedubs.com)
ExceptionNotification::Notifier.sender_address =%("000000book App Error" <noreply@000000book.com>)
ExceptionNotification::Notifier.email_prefix = "[000book] "

