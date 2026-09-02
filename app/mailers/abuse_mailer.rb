class AbuseMailer < ApplicationMailer
  # Same list exception_notification uses. Set in config/application.rb.
  def self.recipients = Rails.application.config.x.alert_recipients

  # Sent when a client crosses one of the rate limits in TagsController. Takes
  # the rate_limit.action_controller payload as it comes, because that is the
  # only thing that ever calls it.
  #
  # Heavily throttled by config/initializers/rate_limit_alerts.rb: one client
  # hammering us must not turn into one email per request.
  def rate_limit_tripped(payload)
    @scope = payload[:scope]
    @name = payload[:name]
    @ip = payload[:by]
    @count = payload[:count]
    @limit = payload[:to]
    @within = payload[:within]

    mail(to: self.class.recipients, subject: "[blackbook] Rate limit tripped: #{@name} by #{@ip}")
  end
end
