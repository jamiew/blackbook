# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper_method :current_user, :page_title, :set_page_title

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
