# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Some globally used exceptions we catch from; MOVEME?
class NoPermissionError < RuntimeError; end

class ApplicationController < ActionController::Base

  helper :all # Oof, REMOVEME -- don't really need all helpers, all the time
  helper_method :current_user_session, :current_user, :page_title, :set_page_title

  filter_parameter_logging :password, :password_confirmation
  protect_from_forgery
  
  # Global filters
  before_filter :activate_authlogic, :set_format, :blackbird_override
  
  # Catch standard exceptions
  rescue_from NoPermissionError, :with => :permission_denied
  



  protected

    def set_page_title(title)
      @page_title = title
    end

    def page_title
      @page_title ? "#{@page_title} - #{SiteConfig.site_name}" : SiteConfig.site_name
    end
  
    def permission_denied      
      logger.error "Permission denied to user #{current_user.login} (##{current_user.id})"
      flash[:error] = "You don't have permission to do that"
      redirect_back_or_default(root_path) #, :status => 403
    end


    # Enable blackbird if ?force_blackbird=true
    def blackbird_override
      if params[:force_blackbird] == 'true'
        session[:blackbird] = true
      end
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
  
    # User shortcuts
    def current_user
      @current_user ||= current_user_session && current_user_session.record
    end
    
    def current_user_session
      @current_user_session ||= UserSession.find
    end
    

    # Authentication checks
    def logged_in?
      return !current_user.nil?
    end
    helper_method :logged_in?
  
    def is_admin?
      !current_user.nil? && current_user.admin?
    end
    alias :admin? :is_admin?
    helper_method :is_admin?, :admin?
    
    # TODO: smarter evaluation of object and "owner" (e.g. use more than just .user; current_object is also unreliable)
    def is_owner?(object = nil)
      object = @current_object if object.nil? && !@current_object.nil? #Hijack into 
      !current_user.nil? && !object.nil? && object.respond_to?(:user) && object.user == current_user
    end
    helper_method :is_owner?


    # Permission requirements
    def require_user
      unless current_user
        store_location
        flash[:error] = "You must be logged in to access that page"
        redirect_to login_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:error] = "You must be logged out to access that page"
        redirect_to(user_path(current_user))
        return false
      end
    end
    
    def require_admin
      raise NoPermissionError if !is_admin?        
    end

    # Stash the current page for use in redirection, e.g. login
    def store_location
      session[:return_to] = request.request_uri
    end

    # Allow for using all 3 of: a specific redirect_to; general :back; OR the default
    def redirect_back_or_default(default)
      unless session[:return_to].blank?        
        redirect_to(session[:return_to])
        session[:return_to] = nil
        return
      end
      redirect_to(:back) and return
    rescue ActionController::RedirectBackError
      redirect_to(default)
    end

    # Set XHR as a totally differnet response format than HTML (don't override .js, we use that)
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
    
    
    # moar 
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

    def dev?
      return RAILS_ENV == 'developmet'
    end
    helper_method :dev?

    # shell for a future a Merb-esque displays/provides syntax
    # TODO: handle arrays better
    # TODO: also handle text...
    def default_respond_to(object, opts={})

      opts = { :exclude => [:id, :created_at, :cached_tag_list] }.merge(opts)
      which_layout = opts[:layout] || false
      # TODO: strip out excluded attributes...

      respond_to do |format|

        # format.html { render :html => object.to_html }      
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
        # - JS
        # - text
        # - RSS
        # - atom
      end and return
    end

end
