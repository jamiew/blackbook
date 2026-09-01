Rails.application.configure do
  config.active_storage.service = :production
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # The health check is the one thing that must answer over plain HTTP. Kamal's
  # proxy polls it on the container directly, without X-Forwarded-Proto, so
  # force_ssl would send it a 301 and it would judge every container unhealthy.
  # Nothing would ever finish deploying.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == '/up' } } }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # In a container the log has to go to stdout, or it goes into a filesystem
  # that is thrown away with the container. Kamal sets this, and without it
  # every exception was written to log/production.log where nobody could
  # read it, which made a 500 indistinguishable from a 504.
  config.logger = ActiveSupport::TaggedLogging.logger($stdout) if ENV["RAILS_LOG_TO_STDOUT"].present?

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Amazon SES over SMTP. The old :sendmail setting assumed a local postfix,
  # which the container does not have, so mail failed silently there.
  #
  # Credentials live in Rails encrypted credentials, not the environment: the
  # encrypted file is safe to commit in a public repo, and RAILS_MASTER_KEY is
  # already handed to the container by Kamal. Edit them with:
  #
  #   bin/rails credentials:edit
  #
  # Falls back to :sendmail when unconfigured, so a laptop and the old server
  # keep behaving as they do today.
  ses = Rails.application.credentials.ses

  if ses.present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ses[:smtp_address],
      port: ses.fetch(:port, 587),
      user_name: ses[:smtp_username],
      password: ses[:smtp_password],
      authentication: :login,
      enable_starttls_auto: true
    }
    config.action_mailer.default_options = { from: ses[:from] }
    # Without this a delivery failure is swallowed and nobody finds out.
    config.action_mailer.raise_delivery_errors = true
  else
    config.action_mailer.delivery_method = :sendmail
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Terse logging via lograge gem
  config.lograge.enabled = true

  # Silence ActiveRecord logging in production (this isn't default?!)
  config.active_record.logger = nil

  # exception_notification
  config.middleware.use ExceptionNotification::Rack,
    ignore_exceptions: ['ActionController::BadRequest'] + ExceptionNotifier.ignored_exceptions,
    email: {
      email_prefix: "[blackbook-prod] ",
      # The SES-verified sender, same as every other mailer. Hardcoding
      # no-reply@000book.com here meant error mail was sent as a domain we no
      # longer use, which SES will refuse once it is not a verified identity.
      sender_address: ses.present? ? ses[:from] : %{"000000book Errors" <no-reply@000000book.com>},
      exception_recipients: config.x.alert_recipients
    }

end
