Rails.application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    :deliver_with => :deliver, # Rails >= 4.2.1 do not need this option since it defaults to :deliver_now
    :email_prefix => "[BLACKBOOK] ",
    :sender_address => %{"000000book Error" <donotreply@000000book.com>},
    :exception_recipients => %w{jamie@jamiedubs.com}
  }
