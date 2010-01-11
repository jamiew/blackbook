class FavoritesController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  # before_filter :require_owner, :only => [:edit, :update, :destroy]
  
  def index
    render :text => "TODO", :layout => true
  end
  
  # Double-duty favorite/unfavorite -- seems better than individual controller favorite/unfavorites
  # Double-duty create cuz DELETE requires specifying a specific object -- we just want something generic. 
  # TODO: allow DELETE to .index as 'unfavorite'?
  def create
    
    #FIXME: hardcoded to Tag currently. Should support more -- extract from nested route
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
