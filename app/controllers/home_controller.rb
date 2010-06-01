class HomeController < ApplicationController

  caches_action :index, :cache_path => 'home/index', :expires_in => 30.minutes, :if => :cache_request?

  def index
    # @users = User.find(:all, :order => 'created_at DESC', :limit => 10)
    @tags = Tag.find(:all, :order => 'created_at DESC', :limit => 30, :include => [:user])
    @tag = @tags.shift
  end

  def activity
    @page, @per_page = params[:page] && params[:page].to_i || 1, 20
    @notifications = Notification.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC', :include => [:subject])
    set_page_title "Activity"
  end

  # Show a single static file
  # FIXME -- hardcoded references to haml & erb
  def static
    if (File.exist?("#{RAILS_ROOT}/app/views/pages/#{params[:id]}.html.haml") || File.exist?("#{RAILS_ROOT}/app/views/pages/#{params[:id]}.html.erb"))
      set_page_title params[:id].capitalize
      render :template => "pages/#{params[:id]}"
    else
      render :file => "public/404.html"
    end
  end

  # Ghetto handling for "bad" URLs -- I'm mapping them here as a blackhole
  def discard
    logger.warn "Discarding request..."
    render :nothing => true, :status => 420 #LOL
  end
end
