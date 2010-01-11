class TagsController < ApplicationController
  
  # We allow access to :create for the ghetto-API, which doesn't require real authentication
  #TODO: change it to something like 'require_api_key' for if it doesn't have a user, or requires http basic...
  before_filter :get_tag, :only => [:show, :edit, :update, :destroy]
  before_filter :require_user, :only => [:new, :edit, :update, :destroy] # <-- but not create
  protect_from_forgery :except => [:create] # for the "API"  
  before_filter :require_owner, :only => [:edit, :update, :destroy]
  before_filter :convert_app_id_to_app_name, :only => [:update, :create]
  
  # Basic caching for :index?page=1 and :show actions
  after_filter :expire_caches, :only => [:update, :create, :destroy]
  caches_action :index, :expires_in => 30.minutes, :if => :cache_request?
  caches_action :show,  :expires_in => 30.minutes, :if => :cache_request?
  
  #TODO: this should be a Sweeper. but it doesn't *have* to be...
  def expire_caches
    if @tag
      expire_fragment(:controller => 'tags', :action => 'show', :id => @tag.id)
      ['json','gml','xml','rss'].each { |format| expire_fragment(:controller => 'tags', :action => 'show', :id => @tag.id, :format => format) }
      Rails.cache.write(@tag.gml_hash_cache_key, @tag.convert_gml_to_hash) #Model caching, but handling all in the controller
    end
    expire_fragment(:controller => 'tags', :action => 'index')
    # expire_fragment(:controller => 'home', :action => 'index')
    expire_fragment('home/index')
  end
  
  # Display
  def index
    
    # Setup a 'search' context -- user or app currently, for finding things not really 'in' the database... more TODO    
    if !params[:app].blank?
      @search_context = {:key => :application, :value => params[:app], :conditions => ["application = ? OR gml_application = ?",params[:app],params[:app]] }
    elsif !params[:user].blank?
      # Specifically customized for the secret_username using gml_uniquekey_hash trailing 5 digits! breakable coupling!
      @search_context = {:key => :user, :value => params[:user], :conditions => ["gml_uniquekey_hash LIKE ?",'%'+params[:user].gsub('anon-','')] }
    end
    
    @page, @per_page = params[:page] && params[:page].to_i || 1, 15
    @tags ||= Tag.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC', :include => [:user], :conditions => (@search_context && @search_context[:conditions]))
    
    
    set_page_title "Tag Data"+(@search_context ? ": #{@search_context[:key]}=#{@search_context[:value].inspect} " : '')+(@page > 1 ? " (page #{@page})" : '')
    
    respond_to do |wants|
      wants.html { render }      
      wants.xml  { render :xml => @tags.to_xml(:dasherize => false, :except => Tag::HIDDEN_ATTRIBUTES, :skip_types => true) }
      wants.json { render :json => @tags.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback], :processingjs => params[:processingjs] }
      wants.rss  { render :rss => @tags.to_rss } #TODO: customize RSS feeds more!
      #TODO: .js => Embeddable widget
    end
  end
  
  def show    
    set_page_title "Tag ##{@tag.id}"
    
    # Only need these instance variables when rendering full HTML display (aka ghetto interlok)
     if params[:format] == 'html' || params[:format] == nil
      @prev = Tag.find(:last, :conditions => "id < #{@tag.id}")
      @next = Tag.find(:first, :conditions => "id > #{@tag.id}")
    
      @user = User.find(params[:user_id]) if params[:user_id]
      @user ||= @tag.user # ...

      # Some ghetto 'excludes' stripping until Tag after_save cleanup is working 100%
      @tag.gml.gsub!(/\<uniqueKey\>.*\<\/uniqueKey>/,'')
    end
    
    
    # fresh_when :last_modified => @tag.updated_at.utc, :etag => @tag    
    respond_to do |wants|
      wants.html  { render }
      wants.gml   { render :xml => @tag.gml }      
      wants.xml   { render :xml => @tag.to_xml(:except => Tag::HIDDEN_ATTRIBUTES, :dasherize => false, :skip_types => true) }      
      wants.json  { render :json => @tag.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback] }
      wants.rss   { render :rss => @tag.to_rss(:except => Tag::HIDDEN_ATTRIBUTES) }
      #TODO: .js => Embeddable widget
    end
  end
  
  # Quick accessor to grab the latest tag -- great for running installations with the freshest GML
  # Hand off to :show except for HTML, which should redirect -- keep permalinks happy
  def latest
    @tag = Tag.find(:first, :order => 'created_at DESC')
    redirect_to(tag_path(@tag), :status => 302) and return if [nil,'html'].include?(params[:format])
    show
  end
  
  # Just a random tag -- redirect to canonical for HTML, but otherwise don't bother (API)
  # TODO DRY with .latest above! generic 'solo' method? wrap into show? hmm
  def random
    @tag = Tag.random
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
    # redirect_to(tags_path)
    redirect_to :back
  end
  
protected
  
  def get_tag
    # @tag ||= Tag.find(params[:tag_id])
    @tag = Tag.find(params[:id])
  end
  
  def require_owner
    logger.info "require_owner (tag.id=#{@tag.id rescue nil}): current_user=#{current_user.id rescue nil}; tag.user.id=#{@tag.user.id rescue nil}"
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
        
    # Read the GML uploaded gml file and dump it into the GML field
    # GML file overrides anything in the textarea -- that was probably accidental input
    file = params[:tag][:gml_file]
    if file
      logger.info "Reading from GML file = #{file.inspect}"
      params[:tag][:gml] = file.read
    end
        
    # Build object    
    @tag = Tag.new(params[:tag])
    
    # GML data of some kind is required -- catching this ourselves due to GMLObject complexity...
    # Allowing screenshot-only's for now... delete later.
    # if params[:tag].blank? || params[:tag][:gml].blank?
    #   @tag.errors.add("You must provide valid GML data to upload (no screenshots only, sorry)")
    #   raise "bad GML data"      
    # end
    
    @tag.save!
    flash[:notice] = "Tag created"
    redirect_to tag_path(@tag)      
  rescue      
    flash[:error] = "Error saving your tag! #{$!}"
    render :action => 'new', :status => 422 #Unprocessable entity
  end
  
  # For converting from the pre-existing 'Application' params into a string in create/update
  # GHETTO. FIXME... Undescriptive method name. 
  def convert_app_id_to_app_name
    # Sub in an existing application if specified...
    return unless params[:tag] && params[:tag][:existing_application_id] && params[:tag][:application].blank?

    # FIXME use internal ids if available? string matching all the time is ghetto
    app = Visualization.find(params[:tag][:existing_application_id]) rescue nil
    params[:tag][:application] = app.name unless app.blank?
  end
    
  
  
  
  
end
