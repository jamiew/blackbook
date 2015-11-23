class HomeController < ApplicationController

  # caches_action :index, :cache_path => 'home/index', :expires_in => 30.minutes, :if => :cache_request?

  def index
    @tags = Tag.order('created_at DESC').limit(30).includes(:user)
    @tag = @tags.present? && @tags.first # formerly .shift to pop it off, should do that on frontend
    set_page_title("#000000book - an open database for Graffiti Markup Language (GML) files", false)
  end

  def activity
    @page, @per_page = params[:page] && params[:page].to_i || 1, 20
    @notifications = Notification.paginate(page: @page, per_page: @per_page).order('created_at DESC').includes(:subject)
    set_page_title "Activity"
  end

  def about
    set_page_title 'About'
  end

  # Ghetto handling for known-bad URLs -- mapping them here as a blackhole
  def discard
    logger.warn "Discarding request..."
    render :nothing => true, :status => 304 # Not Modified
  end

end
