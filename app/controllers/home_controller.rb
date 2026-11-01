class HomeController < ApplicationController
  def index
    @set = params[:set].presence_in(Tag::SETS.keys) || 'featured'
    @tags = curated_tags(@set)
    # The browse layout plays one tag beside the grid: ?tag=id, or the first.
    @tag = (params[:tag].present? && Tag.find_by(id: params[:tag])) || @tags.first
    @browse = true
    @quiet = true
    set_page_title("#000000book - an open database for Graffiti Markup Language (GML) files", false)
  end

  def activity
    @page, @per_page = pagination_params
    @notifications = Notification.paginate(page: @page, per_page: @per_page).order(id: :desc).includes(:subject)
    set_page_title "Activity"
  end

  # Thirty from the set. Featured is canvasplayer's picks in their own order,
  # then the newest to fill the grid: stale by design, a front page that
  # previews well beats one that changes every hour.
  def curated_tags(set)
    scope = Tag.with_attached_image.includes(:user)
    return Tag.curated(set).merge(scope).limit(30).to_a unless set == 'featured'

    featured = scope.where(id: Tag::FEATURED).index_by(&:id).values_at(*Tag::FEATURED).compact
    (featured + scope.order(created_at: :desc).limit(30).to_a).uniq.first(30)
  end

  def upload
    set_page_title 'Make and upload a tag'
  end

  # The static pages, the docs, every approved app and the newest 500 tags.
  # The archive has 76,000 tags; the rest are reachable through /data, and the
  # API is the better way in for anything that wants them all.
  def sitemap
    @docs = DocsPage.all
    @apps = Visualization.approved.select(:id, :updated_at)
    @tags = Tag.order(created_at: :desc).limit(500).select(:id, :updated_at)
    expires_in 1.day, public: true
  end

  def about
    # Six of the archive's own tags, alive, as the page's second graphic.
    @tags = Array.new(6) { Tag.random }.compact.uniq
    set_page_title 'About'
  end

  # Ghetto handling for known-bad URLs -- mapping them here as a blackhole
  def discard
    logger.warn "Discarding request..."
    head :not_modified
  end
end
