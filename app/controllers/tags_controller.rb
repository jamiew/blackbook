class TagsController < ApplicationController

  before_filter :get_tag, :only => [:show, :edit, :update, :destroy]
  protect_from_forgery :except => [:create] # for the "API"

  # Display
  def index
    @page, @per_page = params[:page] || 1, 10
    @tags = Tag.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC')
  end
  
  def show
    @user = User.find(params[:user_id]) if params[:user_id]
    @prev = Tag.find(:last, :conditions => "id < #{@tag.id}")
    @next = Tag.find(:first, :conditions => "id > #{@tag.id}")
    
    respond_to do |wants|
      wants.html { render }
      wants.xml   { render :xml => @tag.to_xml }
      wants.gml   { render :xml => @tag.gml } #TODO: account for nil gml'z -- e.g. make an empty thing or throw error?
      wants.json  { render :json => @tag.to_json }
      wants.rss   { render :rss => @tag.to_rss }
    end
  end
  
  # Quick hack to dump the latest tag -- TODO render HTML too? or redirect
  def latest
    @tag = Tag.find(:first, :order => 'created_at DESC')
    respond_to do |wants|
      # wants.html { render :action => 'show' }
      wants.html  { redirect_to(tag_path(@tag, :trailing_slash => true), :status => 302) } #Temporary Redirect
      wants.gml   { render :xml => @tag.gml }
    end    
  end
  
  # Create/edit tags
  def new
    require_user
    @tag = Tag.new
  end
  
  def edit
    require_user
    require_owner
    @editing = "STUPIDFACE"
    puts "AHHHHHHHHH"
    render :action => 'new' # Hmm, doing :action is bunk, and rails 2.2 doesn't have just render 'new'
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
    require_user
    require_owner
    @tag.update_attributes(params[:tag])
    if @tag.save    
      flash[:notice] = "Tag ##{@tag.id} updated"
      redirect_to tag_path(@tag, :trailing_slash => true)
    else
      flash[:error] = "Could not update tag: #{$!}"
      render :action => 'edit'
    end
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
    @tag = Tag.find(params[:id])
  end
  
  def require_owner
    unless @tag.user == current_user || current_user.login == "jamiew"
      raise "You don't have permission to do this!"
    end
  end
  
  def create_from_form
    params[:tag][:user] = current_user #set here vs. in the form      
    @tag = Tag.new(params[:tag])

    if @tag.save
      flash[:notice] = "Tag created"
      redirect_to tag_path(@tag, :trailing_slash => true)
    else
      flash[:error] = "Error saving your tag! #{$!}"
      error_status = 500
      render :action => 'new', :status => error_status
    end        
  end
  
  def create_from_api

    # TODO: add app uuid? or Hash app uuid?
    opts = { :gml => params[:gml], :ip => request.remote_ip, :application => params[:application], :remote_secret => params[:secret] }
    puts "TagsController.create_from_api, opts=#{opts.inspect}"
    
    @tag = Tag.new(opts)
    if @tag.save
      render :text => @tag.id, :status => 200 #OK
    else
      logger.error "Could not create tag from API: #{@tag.errors.inspect}"
      render :text => "ERROR: #{@tag.errors.inspect}", :status => 422 #Unprocessable Entity
    end
  end
    
  
  
  
  
end
