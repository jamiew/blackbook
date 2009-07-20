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
    if @tag.save
      flash[:notice] = "Tag created"
      redirect_to @tag
    else
      flash[:error] = "Could not save tag!"
      render :action => 'new'
    end        
  end
  
  def update
    #TODO
  end
  
  def destroy
    #TODO
  end
  
  
  
  
end
