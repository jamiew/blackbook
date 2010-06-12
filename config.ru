ENV['RAILS_ENV'] = ENV['RACK_ENV']
require "config/environment"

use Rails::Rack::LogTailer
use Rails::Rack::Static
run ActionController::Dispatcher.new
