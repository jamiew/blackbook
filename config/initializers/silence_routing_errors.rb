# Keep 404s from bots and stale asset URLs out of the production log.
# via https://stackoverflow.com/questions/33827663/hide-actioncontrollerroutingerror-in-logs-for-assets
if Rails.env.production?
  module SilenceRoutingErrors
    def log_error(request, wrapper)
      return if wrapper.exception.is_a?(ActionController::RoutingError)

      super
    end
  end

  ActionDispatch::DebugExceptions.prepend(SilenceRoutingErrors)
end
