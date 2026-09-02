class HomeController < ApplicationController
  def index
    # Loaded up front because the page reads the same 30 rows four ways, and an
    # unloaded relation would run a query for each.
    @tags = Tag.order(created_at: :desc).limit(30).with_attached_image.includes(:user).load
    @tag = @tags.first
    @prev = @tags.second
    # Oldest on the left, like the tag page's strip; @tags is newest first.
    @strip = @tags.first(16).reverse
    set_page_title("#000000book - an open database for Graffiti Markup Language (GML) files", false)
  end

  def activity
    @page, @per_page = pagination_params
    @notifications = Notification.paginate(page: @page, per_page: @per_page).order(id: :desc).includes(:subject)
    set_page_title "Activity"
  end

  def about
    # Six of the archive's own tags, alive, as the page's second graphic.
    @tags = Array.new(6) { Tag.random }.compact.uniq
    set_page_title 'About'
  end

  # Ghetto handling for known-bad URLs -- mapping them here as a blackhole
  def discard
    logger.warn "Discarding request..."
    render nothing: true, status: :not_modified # Not Modified
  end
end
