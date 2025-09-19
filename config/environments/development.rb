Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Propshaft serves assets in development without preprocessing

  # Enable server timing
  config.server_timing = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Silence asset debugging
  config.assets.quiet = true

  # Prevents from writing logs on `log/development.log`
  # logger           = ActiveSupport::Logger.new(STDOUT)
  # logger.formatter = config.log_formatter
  # config.logger    = ActiveSupport::TaggedLogging.new(logger)

  # Propshaft doesn't need precompiled asset checking

end
