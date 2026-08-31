require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
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

    # Rails 8 defaults to :vips. ImageMagick is what Paperclip used, what this
    # app has always depended on, and what the Dockerfile and a plain macOS
    # setup both already have; vips would need installing separately. The
    # image also ships libvips42, so switching is a one-line change later.
    config.active_storage.variant_processor = :mini_magick

    # 8.1 default is :raise. The GML upload API deliberately takes a caller-supplied
    # `?redirect_to=` with `allow_other_host: true`, so a scheme-less value like
    # "example.com" is an expected input, not an attack we can reject.
    config.action_controller.action_on_path_relative_redirect = :log

    # Where operational alerts go: rate limit trips and exception notifications.
    # One place so the two cannot drift apart. Set ALERT_EMAIL to change it
    # without a code change; config/deploy.yml can supply it.
    config.x.alert_recipients = ENV.fetch('ALERT_EMAIL', 'jamie@jamiedubs.com').split(',')

    # The fallback sender. Production replaces it with the address SES has
    # actually verified, from encrypted credentials. It lives here rather than
    # as a `default from:` in ApplicationMailer because a mailer-class default
    # overrides this, which is how outgoing mail ended up claiming to come from
    # 000book.com long after we stopped using that domain.
    config.action_mailer.default_options = { from: '000000book <no-reply@000000book.com>' }

    # Use RSpec for generators
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
