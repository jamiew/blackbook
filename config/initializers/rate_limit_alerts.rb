# Email when someone crosses a rate limit, so the limits in TagsController can
# be tuned against real traffic instead of guesses. Rails 8's rate_limit
# instruments every trip; we subscribe rather than hooking the controller so the
# alerting stays out of the request path's way.
#
# The throttling below is the whole point of this file. The notification fires
# once per *request* over the limit, so a client hammering us at 10 req/s would
# otherwise generate 10 emails a second: a self-inflicted flood, a shredded SES
# reputation, and an amplification vector handed to the attacker. Two caps:
# one email per hour per client, and no more than ten per hour in total.
#
# Rails.cache is the file store, which is per-container and wiped on deploy.
# That is fine here. The worst case of losing the counter is one extra email.
module RateLimitAlerts
  PER_CLIENT_INTERVAL = 1.hour
  GLOBAL_CAP = 10
  GLOBAL_INTERVAL = 1.hour

  class << self
    def enabled?
      Rails.env.production? && Rails.application.credentials.ses.present?
    end

    # Rails.cache#write with unless_exist returns false when the key is already
    # there, which makes "have I sent this recently?" a single atomic call.
    def claim(key, expires_in:)
      Rails.cache.write(key, true, expires_in: expires_in, unless_exist: true)
    end

    def under_global_cap?
      count = Rails.cache.increment('rate_limit_alerts/global', 1, expires_in: GLOBAL_INTERVAL)
      count.nil? || count <= GLOBAL_CAP
    end

    def deliver(payload)
      return unless enabled?

      by = payload[:by]
      return unless claim("rate_limit_alerts/#{payload[:scope]}/#{payload[:name]}/#{by}",
                          expires_in: PER_CLIENT_INTERVAL)
      return unless under_global_cap?

      AbuseMailer.rate_limit_tripped(payload).deliver_later
    end
  end
end

ActiveSupport::Notifications.subscribe('rate_limit.action_controller') do |event|
  # Never let alerting break the response the limiter is trying to send.
  RateLimitAlerts.deliver(event.payload)
rescue StandardError => e
  Rails.logger.error "RateLimitAlerts failed: #{e.class}: #{e.message}"
end
