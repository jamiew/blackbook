class ApplicationMailer < ActionMailer::Base
  # There is deliberately no `default from:` here.
  #
  # A mailer-class default overrides config.action_mailer.default_options, and
  # production sets that from the SES credentials -- the address SES has
  # actually verified. The default that used to live here won that fight, so
  # every message claimed to come from 000book.com, a domain we no longer use.
  # The fallback for development and test is in config/application.rb.
  default_url_options[:host] = '000000book.com'
  layout 'mailer'
end
