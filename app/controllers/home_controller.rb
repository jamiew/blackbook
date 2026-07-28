class HomeController < ApplicationController
  # caches_action :index, cache_path: 'home/index', expires_in: 30.minutes, if: :cache_request?

  def index
    @tags = Tag.order(created_at: :desc).limit(30).includes(:user)
    @tag = (@tags.present? && @tags[0]) || nil
    @prev = (@tags.present? && @tags[1]) || nil
    set_page_title("#000000book - an open database for Graffiti Markup Language (GML) files", false)
  end

  def activity
    @page, @per_page = pagination_params
    @notifications = Notification.paginate(page: @page, per_page: @per_page).order(id: :desc).includes(:subject)
    set_page_title "Activity"
  end

  def about
    set_page_title 'About'
  end

  # Ghetto handling for known-bad URLs -- mapping them here as a blackhole
  def discard
    logger.warn "Discarding request..."
    render nothing: true, status: :not_modified # Not Modified
  end
end
