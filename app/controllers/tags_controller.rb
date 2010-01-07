class TagsController < ApplicationController
  
  # We allow access to :create for the ghetto-API, which doesn't require real authentication
  #TODO: change it to something like 'require_api_key' for if it doesn't have a user, or requires http basic...
  before_filter :get_tag, :only => [:show, :edit, :update, :destroy]
  before_filter :require_user, :only => [:new, :edit, :update, :destroy] # <-- but not create
  protect_from_forgery :except => [:create] # for the "API"  
  before_filter :require_owner, :only => [:edit, :update, :destroy]

  # Basic caching for :index?page=1 and :show actions
  after_filter :expire_caches, :only => [:update, :create, :destroy]
  caches_action :index, :expires_in => 30.minutes, :if => :logged_out_and_no_query_vars?
  caches_action :show,  :expires_in => 30.minutes, :if => :logged_out_and_no_query_vars?
  
  #TODO: this should be a Sweeper. but it doesn't *have* to be...
  def expire_caches
    if @tag
      [nil,'json','gml','xml','rss'].each { |format| expire_fragment(:controller => 'tags', :action => 'show', :id => @tag.id, :format => format) }
    end
    expire_fragment(:controller => 'tags', :action => 'index')
    # expire_fragment(:controller => 'home', :action => 'index')
    expire_fragment('home/index')
  end
  
  # Display
  def index
    @page, @per_page = params[:page] && params[:page].to_i || 1, 10
    @tags = Tag.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC', :include => [:user])
    set_page_title "Tag Data"+(@page > 1 ? " (page #{@page})" : '')
  end
  
  def show    
    set_page_title "Tag ##{@tag.id}"
    
    # Only need these instance variables when rendering full HTML display (aka ghetto interlok)
     if params[:format] == 'html' || params[:format] == nil
      @prev = Tag.find(:last, :conditions => "id < #{@tag.id}")
      @next = Tag.find(:first, :conditions => "id > #{@tag.id}")
    
      @user = User.find(params[:user_id]) if params[:user_id]
      @user ||= @tag.user # ...
    end
    
    # Some ghetto 'excludes' stripping until Tag after_save cleanup is working 100%
    @tag.gml.gsub!(/\<uniqueKey\>.*\<\/uniqueKey>/,'')
    
    # fresh_when :last_modified => @tag.updated_at.utc, :etag => @tag    
    respond_to do |wants|
      wants.html  { render }
      wants.xml   { render :xml => @tag.to_xml(:dasherize => false, :except => Tag::HIDDEN_ATTRIBUTES, :skip_types => true) }      
      wants.gml   { render :xml => @tag.gml } #TODO: account for empty GML field?
      wants.json  { render :json => @tag.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback] }
      wants.rss   { render :rss => @tag.to_rss }
    end
  end
  
  # Quick accessor to grab the latest tag -- great for running installations with the freshest GML
  # Hand off to :show except for HTML, which should redirect -- keep permalinks happy
  def latest
    @tag = Tag.find(:first, :order => 'created_at DESC')
    redirect_to(tag_path(@tag), :status => 302) and return if [nil,'html'].include?(params[:format])
    show
  end
  
  
  # Create/edit tags
  def new
    @tag = Tag.new    
  end
  
  def edit
    render :action => 'new' # Hmm, doing :action is bunk, and rails 2.2 doesn't have just render 'new'
  end
  
  # branches into create_from_form (on-site, more strict) vs. create_from_api (less strict)
  def create
    raise "No params!" if params.blank?
    render :nothing => true, :status => 200 and return if params[:check] == 'connected' #DustTag weirdness?
    
    if !params[:tag].blank? # sent by the form
      return create_from_form
    elsif !params[:gml].blank? # sent from an app!
      return create_from_api
    else
      # Otherwise error out, without displaying any sensitive or internal params
      clean_params = params
      [:action, :controller].each { |k| clean_params.delete(k) }
      render :text => "Error, could not create tag from your parameters: #{clean_params.inspect}", :status => 422 #Unprocessable Entity
      return
    end
    expire_page(:index)
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
      render :action => 'new', :status => 422 #Unprocessable entity
    end        
  end    
  
  
  
  
end
