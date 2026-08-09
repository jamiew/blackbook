# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper_method :current_user_session, :current_user, :page_title, :set_page_title

  # Don't show raw GML in the logs
  # filter_parameter_logging :password, :password_confirmation, :gml, :data
  # protect_from_forgery

  # before_action :activate_authlogic
  before_action :set_format

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
    @current_user ||= current_user_session&.record
  end

  def current_user_session
    @current_user_session ||= UserSession.find
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

  # Set XHR as a totally differnet response format than HTML
  # We don't want to override .js, we use that for actual javascript
  # FIXME probably no longer applies
  def set_format
    # @template.template_format = 'html'
    request.format = :xhr if request.xhr?
  end

  # Render XHR without :layout by default
  def render(*args)
    if request.xhr?
      if args.blank?
        return super(layout: false)
      elsif args.first.is_a?(Hash) && args.first[:layout].blank?
        args.first[:layout] = false
      end
    end
    super
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
