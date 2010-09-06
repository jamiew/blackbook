class FavoritesController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]

  def index
    @user = User.find(params[:user_id])
    @page, @per_page = params[:page] && params[:page].to_i || 1, 10 #FIXME align with Tags.index...

    # Goofy association-association loading for compat with will_paginate
    # Using double paginate as a 'ghetto limit'. doesn't cause trouble (??)
    fave_objects = @user.favorites.tags.find(:all, :select => 'object_id, created_at')
    # FIXME: object_id causing headaches... rename to 'favorited_id' or something. hmm.
    @tags = @favorites = Tag.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC',
                          :conditions => ['id in (?)', fave_objects.map{|f| f.attributes['object_id']} ] )

    # Keep @tags/@favorites consistent...
    @favorites = @tags

    set_page_title "#{@user.login}'s Favorites"
    render :template => 'tags/index'
  end

  # Double-duty favorite/unfavorite -- seems better than individual controller favorite/unfavorites
  # DELETE requires specifying a specific object -- we just want something generic.
  def create

    # Hardcoded to Tag currently. Should support more -- extract from nested route
    raise "tag_id only!" if params[:tag_id].blank?
    attrs = {:object_id => params[:tag_id], :object_type => 'Tag'}

    fave = current_user.favorites.find(:first, :conditions => attrs)
    if fave
      fave.destroy
      flash[:notice] = "Unfavorited..."
    else
      current_user.favorites.create!(attrs)
      flash[:notice] = "Favorited!"
    end
    redirect_to :back and return
  end

end
