# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper_method :current_user, :page_title, :set_page_title

  # Rate limiting keeps its own store rather than sharing Rails.cache, which is
  # an unconfigured file store backing the expensive Tag#gml_hash GML parse.
  # One host, one Puma process, so an in-memory counter is accurate. It resets
  # on deploy and is not shared during the two-container rollover; both are
  # acceptable for a first version. See docs/operations.md.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)

  # Rails interpolates a JSONP callback into the response body without escaping
  # it, as `/**/name(...)`. Anything that is not a plain function name is
  # dropped rather than reflected back at whoever asked for it.
  JSONP_CALLBACK = /\A[A-Za-z_$][\w$.]{0,63}\z/

  # Don't show raw GML in the logs
  # filter_parameter_logging :password, :password_confirmation, :gml, :data
  # protect_from_forgery

  # before_action :activate_authlogic

  # Beta gate. Lives here rather than in nginx because kamal-proxy owns ports
  # 80 and 443 and has no basic auth of its own. Set both env vars to enable it;
  # unset, the site is open, which is what production wants.
  #
  # /up is unaffected because Rails::HealthController descends from
  # ActionController::Base, not from here. That matters: kamal-proxy polls it to
  # decide whether a container is healthy, and a 401 there would mean no deploy
  # ever completes.
  if ENV["BETA_AUTH_USER"].present? && ENV["BETA_AUTH_PASSWORD"].present?
    http_basic_authenticate_with(
      name: ENV.fetch("BETA_AUTH_USER"),
      password: ENV.fetch("BETA_AUTH_PASSWORD")
    )
  end

  rescue_from NoPermissionError, with: :permission_denied

  # Oink object debugging in dev
  # if Rails.env == 'development'
  #   include Oink::MemoryUsageLogger
  #   include Oink::InstanceTypeCounter
  # end

  protected

  def jsonp_callback
    callback = params[:callback].presence
    callback if callback&.match?(JSONP_CALLBACK)
  end

  # True when the client's cached copy is still good and we should stop here.
  #
  # HTML never validates: those pages render an owner/admin modbox, so a public
  # validator would hand one visitor another visitor's view. API responses are
  # the same for everyone, which is what makes `public: true` safe.
  def cached_for_api?(**validators)
    return false if request.format.html?

    !stale?(**validators, public: true)
  end

  # The `with:` handler for rate_limit. Rails' default raises and renders a 429
  # HTML page, which is no use to a client that asked for .json or .gml, so this
  # answers in the requested format and says when to come back. It renders
  # directly rather than going through require_user and friends, which redirect
  # with a flash and cannot produce a machine-readable status.
  def too_many_requests(retry_after:)
    response.headers['Retry-After'] = retry_after.to_i.to_s
    # Duration#inspect already reads as "1 minute" / "1 hour"
    message = "Rate limit exceeded. Try again in #{retry_after.inspect}."

    # Switched on the requested format rather than negotiated with respond_to.
    # Most API clients send `Accept: */*`, which negotiation resolves to whatever
    # is declared first -- so a plain `POST /data`, whose success response is
    # plain text, would get a JSON error. Match the format the client asked for.
    case request.format.symbol
    when :json
      render json: { error: message }, status: :too_many_requests, callback: jsonp_callback
    when :xml
      render xml: { error: message }.to_xml(root: 'error'), status: :too_many_requests
    else
      render plain: message, status: :too_many_requests
    end
  end

  # Safe pagination parameter handling with customizable defaults
  def pagination_params(page: nil, per_page: 20, max_per_page: 100)
    requested_per_page = params[:per_page]&.to_i
    safe_per_page = if requested_per_page&.positive?
                      [requested_per_page, max_per_page].min
                    else
                      per_page
                    end

    [
      [page || params[:page].to_i, 1].max,  # page
      safe_per_page                         # per_page
    ]
  end

  # Modify the global page title -- could also use @page_title
  # TODO change to page_title= (or just use @page_title/@title directly)
  def set_page_title(title, suffix = true)
    title += (suffix ? " - 000000book" : '')
    title += " (page #{@page})" if @page.to_i > 1
    @page_title = title
  end

  def page_title
    @page_title || '000000book'
  end

  # Catch-all render for no-permission errors
  def permission_denied
    flash.now[:error] = "You don't have permission to do that"
    render plain: flash[:error], status: :forbidden
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def log_in(user)
    # Rotating the session id makes a session fixated before login useless.
    # It also empties the session, so carry return_to across by hand or
    # redirect_back_or_default sends everyone to the default instead.
    return_to = session[:return_to]
    reset_session
    session[:return_to] = return_to if return_to.present?
    session[:user_id] = user.id
    @current_user = user
  end

  def log_out
    reset_session
    @current_user = nil
  end

  def logged_in?
    !current_user.nil?
  end
  helper_method :logged_in?

  def is_admin?
    !current_user.nil? && current_user.admin?
  end
  alias admin? is_admin?
  helper_method :is_admin?, :admin?

  # TODO: need smarter evaluation of object and "owner"
  # e.g. use more than just .user -- current_object is also unreliable
  def is_owner?(object = nil)
    object = @current_object if object.nil? && !@current_object.nil? # Hijack into
    !current_user.nil? && !object.nil? && object.respond_to?(:user) && object.user == current_user
  end
  helper_method :is_owner?

  # Permission requirements
  def require_user
    return if current_user

    logger.debug "require_user failed"
    store_location
    flash[:error] = "You must be logged in to do that"
    redirect_to(login_path)
    false
  end

  def require_no_user
    return unless current_user

    logger.debug "require_no_user failed"
    store_location
    flash[:error] = "You must *not* be logged-in to access that."
    # redirect_back_or_default(user_path(current_user))
    redirect_to(user_path(current_user))
  end

  def require_admin
    return if current_user && is_admin?

    logger.warn "require_admin failed (!!)"
    store_location
    flash[:error] =
      "You don't have permission to access this page. Your IP #{request.remote_addr} has been logged & reported."
    # redirect_back_or_default(logged_in? ? root_path : login_path)
    redirect_to(logged_in? ? root_path : login_path)
  end

  # Stash the current page for use in redirection, e.g. login
  # using :back doesn't work inside a POST
  def store_location
    session[:return_to] = request.url
  end

  # Allow for using all 3 of: a specific redirect_to, a general :back, OR the specified default
  # Update: skipping out on using :back -- it causes a lot of goofiness. If you want that kind of functionality,
  #  use :store_location explicitly on the callin page
  def redirect_back_or_default(default, opts = {})
    if session[:return_to].blank?
      # puts "Redirecting to :back ..."
      # redirect_to(:back)
      redirect_to(default, opts)
    else
      Rails.logger.debug { "Redirecting to #{session[:return_to]}" }
      redirect_to(session[:return_to], opts)
      session[:return_to] = nil
    end
  end

  # Request params stripped of internal route info
  def clean_params
    excludes = %i[controller action id format]
    params.reject { |k, _v| excludes.include?(k.to_sym) }
  end

  def dev? = Rails.env.development?
  def production? = Rails.env.production?
  helper_method :dev?, :production?
end
