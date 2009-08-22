class TagsController < ApplicationController

  before_filter :get_tag, :only => [:show, :edit, :update, :destroy]
  protect_from_forgery :except => [:create] # for the "API"

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
      wants.gml { render :xml => @tag.to_xml } #GML => XML
      wants.xml { render :xml => @tag.to_xml }
      wants.json { render :json => @tag.to_json }
      wants.rss { render :rss => @tag.to_rss }
    end
  end
    
  def new
    require_user
    @tag = Tag.new
  end
  
  def edit
    require_user
    render 'new'
  end
  
  def create        
    raise "No params!" if params.blank?
    
    if !params[:tag].blank? # sent by the form
      return create_from_form
    elsif !params[:gml].blank? # sent from an app!
      return create_from_api
    else
      # Otherwise error out
      render :text => "Cannot create tag from your paramters: #{params.inspect}", :status => 422 #Unprocessable Entity
      return
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
  
  def create_from_form
    params[:tag][:user] = current_user #set here vs. in the form      
    @tag = Tag.new(params[:tag])

    if @tag.save
      flash[:notice] = "Tag created"
      redirect_to @tag
    else
      flash[:error] = "Error saving your tag! #{$!}"
      error_status = 500
      render :action => 'new', :status => error_status
    end        
  end
  
  def create_from_api

    opts = { :gml => params[:gml], :ip => request.remote_ip, :application => params[:application] }
    # opts = { :description => params[:gml], :ip => request.remote_ip, :application => params[:application] }    
    # TODO: add app uuid? or Hash app uuid?
    puts "Tag.create_from_api: #{opts.inspect}"

    @tag = Tag.new(opts)
    if @tag.save
      render :text => @tag.id, :status => 200 #OK
    else
      render :text => "ERROR: #{$!}", :status => 422 #Unprocessable Entity
    end
  end
    
  
  
  
  
end
