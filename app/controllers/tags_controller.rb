class TagsController < ApplicationController

  before_filter :get_tag, :only => [:show, :update, :destroy]

  def index
    @page, @per_page = params[:page] || 1, 5
    @tags = Tag.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC')
  end
  
  def show
    @user = User.find(params[:user_id]) if params[:user_id]
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
    raise "No params!" if params.blank? || params[:tag].blank?    
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
    require_user
    require_owner
  end
  
  def destroy
    #TODO
    require_user
    require_owner

    @tag.destroy
    flash[:notice]
    redirect_to user_path(@tag.user)
  end
  
protected
  
  def get_tag
    # @tag ||= Tag.find(params[:tag_id])    
    @tag ||= Tag.find(params[:id])
  end
  
  def require_owner
    unless @tag.user == current_user
      raise "You don't have permission to do this!"
    end
  end
    
  
  
  
  
end
