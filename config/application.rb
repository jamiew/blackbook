require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Blackbook4
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.load_defaults 8.1

    # 8.1 default is :raise. The GML upload API deliberately takes a caller-supplied
    # `?redirect_to=` with `allow_other_host: true`, so a scheme-less value like
    # "example.com" is an expected input, not an attack we can reject.
    config.action_controller.action_on_path_relative_redirect = :log

    # Use RSpec for generators
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
