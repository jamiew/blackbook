ExceptionNotification::Notifier.exception_recipients = %w(jamie@jamiedubs.com)
ExceptionNotification::Notifier.sender_address = %("Application Error" <noreply@000000book.com>)
ExceptionNotification::Notifier.email_prefix = "[00000book] "

ExceptionNotification::Notifier.sender_address = %("Application Error" <exception.notifier@api.140proof.com>)
ExceptionNotification::Notifier.email_prefix = "[#{(defined?(Rails) ? Rails.env : RAILS_ENV).capitalize} ERROR] "

