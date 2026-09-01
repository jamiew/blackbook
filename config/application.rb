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
    # setup both already have; vips would need installing separately.
    config.active_storage.variant_processor = :mini_magick

    # Where GmlObject reads and writes the raw .gml files. A setting rather
    # than a constant so the test environment can point somewhere disposable:
    # the suite writes real files, and sharing this directory means every run
    # overwrites tags with fixtures.
    config.x.gml_data_dir = Rails.root.join("data")

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
