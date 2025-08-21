class FavoritesController < ApplicationController
  before_action :require_user, only: [:create, :update, :destroy]

  def index
    @user = current_user
    @page, @per_page = params[:page] && params[:page].to_i || 1, 10 # FIXME align with Tags.index...

    # Goofy association-association loading for compat with will_paginate
    # Using double paginate as a 'ghetto limit'. doesn't cause trouble (??)
    fave_objects = @user.favorites.tags.select('object_id, created_at').all
    object_ids = fave_objects.map{|f| f.attributes['object_id'] }
    @tags = Tag.order('created_at DESC').where('id in (?)', object_ids).paginate(page: @page, per_page: @per_page)
    @favorites = @tags

    set_page_title "Your Favorites"
    render template: 'tags/index'
  end

  # Double-duty favorite/unfavorite -- seems better than individual controller favorite/unfavorites
  # DELETE requires specifying a specific object -- we just want something generic.
  def create

    # Hardcoded to Tag currently. Should support more -- extract from nested route
    raise "tag_id only!" if params[:tag_id].blank?
    attrs = { object_id: params[:tag_id], object_type: 'Tag' }

    fave = current_user.favorites.find_by(attrs)
    if fave
      fave.destroy
      flash[:notice] = "Unfavorited..."
    else
      current_user.favorites.create!(attrs)
      flash[:notice] = "Favorited!"
    end
    redirect_back(fallback_location: root_path) and return
  end

end
