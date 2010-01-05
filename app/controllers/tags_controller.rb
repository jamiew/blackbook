class TagsController < ApplicationController
  
  # We allow access to :create for the ghetto-API, which doesn't require real authentication
  #TODO: change it to something like 'require_api_key' for if it doesn't have a user, or requires http basic...
  before_filter :get_tag, :only => [:show, :edit, :update, :destroy]
  before_filter :require_user, :only => [:new,:edit,:update,:destroy] # <-- but not create
  protect_from_forgery :except => [:create] # for the "API"  
  before_filter :require_owner, :only => [:edit,:update,:destroy]


  # Display
  def index
    @page, @per_page = params[:page] || 1, 10
    @tags = Tag.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC', :include => [:user])
  end
  
  def show
    
    # Only need these instance vars with full HTML display; this could be Interlok'ed
     if params[:format] == 'html' || params[:format] == nil
      @prev = Tag.find(:last, :conditions => "id < #{@tag.id}")
      @next = Tag.find(:first, :conditions => "id > #{@tag.id}")
    
      @user = User.find(params[:user_id]) if params[:user_id]
      @user ||= @tag.user # ...
    end
    
    respond_to do |wants|
      wants.html  { render }
      wants.xml   { render :xml => @tag.to_xml(:dasherize => false, :except => Tag::HIDDEN_ATTRIBUTES, :skip_types => true) }      
      wants.gml   { render :xml => @tag.gml } #TODO: account for empty GML field?
      wants.json  { render :json => @tag.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback] }
      wants.rss   { render :rss => @tag.to_rss }
    end
  end
  
  # Quick hack to dump the latest tag -- TODO render HTML too? or redirect
  def latest
    @tag = Tag.find(:first, :order => 'created_at DESC')
    respond_to do |wants|
      wants.html  { redirect_to(tag_path(@tag), :status => 302) } #Temporary Redirect
      wants.xml   { render :xml => @tag.to_xml(:dasherize => false, :skip_types => true, :except => Tag::HIDDEN_ATTRIBUTES) }      
      wants.gml   { render :xml => @tag.gml }
      wants.json  { render :json => @tag.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback] }
      wants.rss   { render :rss => @tag.to_rss }      
    end    
  end
  
  # Create/edit tags
  def new
    @tag = Tag.new    
  end
  
  def edit
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
    @tag.update_attributes(params[:tag])
    if @tag.save    
      flash[:notice] = "Tag ##{@tag.id} updated"
      redirect_to tag_path(@tag)
    else
      flash[:error] = "Could not update tag: #{$!}"
      render :action => 'edit'
    end
  end
  
  def destroy
    @tag.destroy
    if @tag.destroy
      flash[:notice] = "Tag ##{@tag.id} destroyed"
    else
      flash[:error] = "Could not destroy tag: #{$!}"
    end
    redirect_to(tags_path)
  end
  
protected
  
  def get_tag
    # @tag ||= Tag.find(params[:tag_id])
    logger.info "params[:id]=#{params[:id]}"
    @tag = Tag.find(params[:id])
  end
  
  def require_owner
    logger.info "require_owner: current_user=#{current_user.id rescue nil}; tag=#{@tag.id rescue nil}; @tag.user=#{@tag.user rescue nil}"
    raise NoPermissionError unless current_user && @tag && (@tag.user == current_user || is_admin?)
  end
  
  
  # Create a tag uploaded w/o a user or authentication, via the ghetto-API
  # this is currently used for tempt from the Eyewriter, but will be expanded...
  def create_from_api

    # TODO: add app uuid? or Hash app uuid?
    opts = { :gml => params[:gml], :ip => request.remote_ip, :application => params[:application], :remote_secret => params[:secret], :image => params[:image] }
    puts "TagsController.create_from_api, opts=#{opts.inspect}"
    
    # Merge opts & params to let people add whatever...
    @tag = Tag.new(opts)
    if @tag.save
      render :text => @tag.id, :status => 200 #OK
    else
      logger.error "Could not create tag from API: #{@tag.errors.inspect}"
      render :text => "ERROR: #{@tag.errors.inspect}", :status => 422 #Unprocessable Entity
    end
  end


  # construct & save a tag submitted manually, through the website
  # We do some strange field expansion right now that could be moved into filters or model accessors
  def create_from_form
    
    # Translate/expand some params
    params[:tag][:user] = current_user    
    
    # Sub in an existing application if specified...
    if params[:tag][:existing_application_id] && !params[:tag][:application]
      puts 'we got a pre-existing...'
      # FIXME use internal ids if available? string matching all the time is ghetto
      app = Visualization.find(params[:tag][:existing_application_id])
      params[:tag][:application] = app.name
      puts "  name = #{app.name.inspect}"
    end
    
    # Read the GML uploaded gml file and dump it into the GML field
    # GML file overrides anything in the textarea -- that was probably accidental input
    file = params[:tag][:gml_file]
    if file
      logger.info "Reading from GML file = #{file.inspect}"
      params[:tag][:gml] = file.read
    end
    
    # Build object
    @tag = Tag.new(params[:tag])

    if @tag.save
      flash[:notice] = "Tag created"
      redirect_to tag_path(@tag)
    else
      flash[:error] = "Error saving your tag! #{$!}"
      error_status = 500
      render :action => 'new', :status => error_status
    end        
  end    
  
  
  
  
end
