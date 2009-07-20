class TagsController < ApplicationController

  def index
    @tags = Tag.all
  end
  
  def show
    @tag = Tag.find(params[:id])
  end
    
  def new
    @tag = Tag.new  
  end
  
  def create
    #TODO
  end
  
  def update
    #TODO
  end
  
  def destroy
    #TODO
  end
  
  
  
  
end
