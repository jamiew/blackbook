# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all

  helper_method :current_user_session, :current_user, :page_title,
    :set_page_title

  filter_parameter_logging :password, :password_confirmation

  before_filter :blackbird_override, :activate_authlogic, :set_format

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def set_page_title(title)
    @page_title = title
  end

  def page_title
    @page_title ? "#{@page_title} - #{SiteConfig.site_name}" : SiteConfig.site_name
  end

  protected

    def blackbird_override
      if 'true' == params[:force_blackbird]
        session[:blackbird] = true
      end
    end

  private
    def current_user_session
      @current_user_session ||= UserSession.find
    end

    def current_user
      @current_user ||= current_user_session && current_user_session.record
    end

    # Authentication checks
    def logged_in?
      return !current_user.nil?
    end
    helper_method :logged_in?
  
    def admin?
      return (!current_user.nil? && current_user.login == "jamiew") #FIXME!
    end
    alias :is_admin? :admin?
    helper_method :admin?, :is_admin?


    # Permission requirements
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to login_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to(user_path)
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def set_format
      @template.template_format = 'html'
      request.format = :xhr if request.xhr?
    end

    def render(*args)
      if request.xhr?
        if args.blank?
          return(super :layout => false)
        else
          args.first[:layout] = false if args.first.is_a?(Hash) &&
            args.first[:layout].blank?
        end
      end
      super
    end
    
    
    # moar 
    def url_escape(str, whitelist=false)
      if whitelist
        # Append to whatever else domains magma may be under
        if !(/^(http|https)(\:\/\/)(www\.)?(lh|localhost|magma\.rocketboom\.com|mag\.ma|hotlikemagma\.com)/i.match(str))
          return ''
        end
      end

      return str.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.tr(' ', '+')
    end
    helper_method :url_escape


    # shell for a future a Merb-esque displays/provides syntax
    # TODO: handle arrays better
    # TODO: also handle text...
    def default_respond_to(object, opts={})

      opts = { :exclude => [:id, :created_at, :cached_tag_list] }.merge(opts)
      puts "exclude = #{opts[:exclude].inspect}"
      which_layout = opts[:layout] || false
      puts "which_layout => #{which_layout}"
      # TODO: strip out excluded attributes

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


    protected

    # Automatically respond with 404 for ActiveRecord::RecordNotFound
    def record_not_found
      render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => 404
    end  

    def fetch_partial(file, opts = {})
      render_to_string :partial => file, :locals => opts
    end
    helper_method :fetch_partial


end
