class HomeController < ApplicationController

  caches_action :index, :cache_path => 'home/index', :expires_in => 30.minutes, :if => :cache_request?

  def index
    @tags = Tag.find(:all, :order => 'created_at DESC', :limit => 30, :include => [:user])
    @tag = @tags.shift
    set_page_title("#000000book - an open database for Graffiti Markup Language (GML) files", false)
  end

  def activity
    @page, @per_page = params[:page] && params[:page].to_i || 1, 20
    @notifications = Notification.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC', :include => [:subject])
    set_page_title "Activity"
  end

  # Show a single static page
  # FIXME using hardcoded references to .haml or .erb... we need template_exists?()
  def static
    template = "pages/#{params[:id]}"
    if template_exists?(template)
      set_page_title params[:id].capitalize
      render :template => template
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
    end
  end

  # Ghetto handling for known-bad URLs -- mapping them here as a blackhole
  def discard
    logger.warn "Discarding request..."
    render :nothing => true, :status => 304 # Not Modified
  end


  private

  def template_exists?(path)
    self.view_paths.find_template(path, response.template.template_format)
  rescue ActionView::MissingTemplate
    false
  end
end
