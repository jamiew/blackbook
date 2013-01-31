# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Common exceptions
class NoPermissionError < RuntimeError; end
class InvalidGMLError < RuntimeError; end

class ApplicationController < ActionController::Base

  helper :all
  helper_method :current_user_session, :current_user, :page_title, :set_page_title

  # Don't show raw GML in the logs
  filter_parameter_logging :password, :password_confirmation, :gml, :data
  protect_from_forgery

  # Global filters
  before_filter :activate_authlogic, :set_format

  # Global exceptions to catch
  rescue_from NoPermissionError, :with => :permission_denied

  # Oink object debugging in dev
  # if RAILS_ENV == 'development'
  #   include Oink::MemoryUsageLogger
  #   include Oink::InstanceTypeCounter
  # end


  protected

  # Log extra info we like
  def log_processing
    super
    if logger && logger.info?
      logger.info("  HTTP Referer: #{request.referer}") if !request.referer.blank?
      logger.info("  User Agent: #{request.env["HTTP_USER_AGENT"]}")
    end
  end

  # Modify the global page title -- could also use @page_title
  # TODO change to page_title= (or just use @page_title/@title directly)
  def set_page_title(title, suffix = true)
    title += (suffix ? " - #{SiteConfig.site_name}" : '')
    title += " (page #{@page})" if @page.to_i > 1
    @page_title = title
  end

  def page_title
    if @page_title
      @page_title
    else
      SiteConfig.site_name
    end
  end

  # Catch-all render for no-permission errors
  def permission_denied
    flash[:error] = "You don't have permission to do that"
    render :text => flash[:error], :status => 403
  end

  # Automatically respond with 404 for ActiveRecord::RecordNotFound
  def record_not_found
    render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => 404
  end

  # Render a partial into a string
  def fetch_partial(file, opts = {})
    render_to_string :partial => file, :locals => opts
  end
  helper_method :fetch_partial

  private

  def current_user
    @current_user ||= current_user_session && current_user_session.record
  end

  def current_user_session
    @current_user_session ||= UserSession.find
  end

  def logged_in?
    return !current_user.nil?
  end
  helper_method :logged_in?

  def is_admin?
    !current_user.nil? && current_user.admin?
  end
  alias :admin? :is_admin?
  helper_method :is_admin?, :admin?

  # TODO need smarter evaluation of object and "owner"
  # e.g. use more than just .user -- current_object is also unreliable
  def is_owner?(object = nil)
    object = @current_object if object.nil? && !@current_object.nil? #Hijack into
    !current_user.nil? && !object.nil? && object.respond_to?(:user) && object.user == current_user
  end
  helper_method :is_owner?


  # Permission requirements
  def require_user
    unless current_user
      logger.info "require_user failed"
      store_location
      flash[:error] = "You must be logged in to do that"
      redirect_to(login_path)
      return false
    end
  end

  def require_no_user
    if current_user
      logger.info "require_no_user failed"
      store_location
      flash[:error] = "You must *not* be logged-in to access that."
      # redirect_back_or_default(user_path(current_user))
      redirect_to(user_path(current_user))
    end
  end

  def require_admin
    unless current_user && is_admin?
      logger.warn "require_admin failed (!!)"
      store_location
      flash[:error] = "You don't have permission to access this page. Your IP #{request.remote_addr} has been logged & reported."
      # redirect_back_or_default(logged_in? ? root_path : login_path)
      redirect_to(logged_in? ? root_path : login_path)
    end
  end

  # Stash the current page for use in redirection, e.g. login
  # using :back doesn't work inside a POST
  def store_location
    session[:return_to] = request.request_uri
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
      puts "Redirecting to #{session[:return_to]}"
      redirect_to(session[:return_to], opts)
      session[:return_to] = nil
    end
  rescue ActionController::RedirectBackError
    redirect_to(default, opts)
  end

  # Set XHR as a totally differnet response format than HTML
  # We don't want to override .js, we use that for actual javascript
  def set_format
    @template.template_format = 'html'
    request.format = :xhr if request.xhr?
  end

  # Render XHR without :layout by default
  def render(*args)
    if request.xhr?
      if args.blank?
        return(super :layout => false)
      else
        args.first[:layout] = false if args.first.is_a?(Hash) && args.first[:layout].blank?
      end
    end
    super
  end

  # Generic responses, Merb-esque displays/provides
  # TODO handle arrays better
  def default_respond_to(object, opts={})

    opts = { :exclude => [:id, :created_at, :cached_tag_list] }.merge(opts)
    which_layout = opts[:layout] || false
    # TODO strip out excluded attributes

    respond_to do |format|
      format.html {
        if request.xhr? && !opts[:html_partial].blank?
          render :partial => opts[:html_partial], :object => object
        else
          render :text => object.to_html(:exclude => opts[:exclude]), :layout => which_layout
        end
      }

      format.xml  { render :text => object.to_xml }
      format.json { render :text => object.to_json }
      format.yaml { render :text => object.to_yaml }
      # TODO: js, txt, rss, atom
    end and return
  end

  # Should we cache this request? A good question!
  def cache_request?
    return false unless clean_params.blank? # Never cache if we have query vars (e.g. ?page=1, or ?callback=setup)
    return true unless [nil,'','html'].include?(request.parameters[:format].to_s) # Always cache if it's not HTML - json/gml/xml are the same for everyone
    return true if request.session['user_credentials_id'].blank? # Never cache if logged in
  end

  # Request params stripped of internal route info
  def clean_params
    excludes = [:controller, :action, :id, :format]
    return params.reject { |k,v| excludes.include?(k.to_sym) }
  end

  def url_escape(str, whitelist=false)
    if whitelist
      # Append to whatever else domains app may be under
      if !(/^(http|https)(\:\/\/)(www\.)?(lh|localhost|000000book\.com)/i.match(str))
        return ''
      end
    end

    return str.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '+')
  end
  helper_method :url_escape

  def dev?; RAILS_ENV == 'development'; end
  def production?; RAILS_ENV == 'production'; end
  helper_method :dev?, :production?

end
