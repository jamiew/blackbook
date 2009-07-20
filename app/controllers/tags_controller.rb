class TagsController < ApplicationController

  def index
    @tags = Tag.all
  end
  
  def show
    @tag = Tag.find(params[:id])
  end
    
  def new
    require_user
    @tag = Tag.new  
  end
  
  def create
    #TODO
    raise "No params!" if params.blank? || params[:tag].blank?
    @tag = Tag.new(params[:tag])
    @tag.save!
    redirect_to @tag
  end
  
  def update
    #TODO
  end
  
  def destroy
    #TODO
  end
  
  
  
  
end
