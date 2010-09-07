ENV["RAILS_ENV"] = 'test'

require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
require 'spec/autorun'
require 'spec/rails'
# require 'webrat/integrations/rspec-rails'

require 'authlogic/test_case'
require RAILS_ROOT+'/spec/factories'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}


Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # Flush memcache between every test case
  config.before(:each) do
    $memcache.flush_all unless $memcache.nil?
  end
end


# Authentication-related spec helpers
def login_as_user(user = nil)
  user ||= Factory(:user)
  UserSession.create(user)
end

def login_as_admin(admin = nil)
  admin ||= Factory(:admin)
  UserSession.create(admin)
end

def logout
  current_user_session.destroy
end

# FIXME these are copied from ApplicationController
# what are the typical procedures for AuthLogic...?
def current_user
  @current_user ||= current_user_session && current_user_session.record
end

def current_user_session
  @current_user_session ||=UserSession.find
end

