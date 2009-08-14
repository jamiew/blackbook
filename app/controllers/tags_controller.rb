class TagsController < ApplicationController

  def index
    @tags = Tag.all
  end
  
  def show
    @tag = Tag.find(params[:id])
    @prev = Tag.find(:last, :conditions => "id < #{@tag.id}")
    @next = Tag.find(:first, :conditions => "id > #{@tag.id}")
    
    respond_to do |wants|
      wants.html { render }
      wants.xml { render :xml => @tag.to_xml }
      wants.json { render :json => @tag.to_json }
      wants.rss { render :rss => @tag.to_rss }
    end
  end
    
  def new
    require_user
    @tag = Tag.new
  end
  
  def create
    #TODO
    raise "No params!" if params.blank? || params[:tag].blank?
    puts params[:tag].inspect
    params[:tag][:user] = current_user #set here vs. in the form
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
