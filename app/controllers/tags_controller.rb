class TagsController < ApplicationController

  # We allow access to :create for the ghetto-API, which doesn't require real authentication
  #TODO: change it to something like 'require_api_key' for if it doesn't have a user, or requires http basic...
  before_filter :get_tag, :only => [:show, :edit, :update, :destroy, :thumbnail, :nominate]
  before_filter :require_user, :only => [:new, :edit, :update, :destroy, :nominate] # <-- but not create
  protect_from_forgery :except => [:create, :thumbnail] # for the "API"
  before_filter :require_owner, :only => [:edit, :update, :destroy]
  before_filter :convert_app_id_to_app_name, :only => [:update, :create]

  # Basic caching for :index?page=1 and :show actions
  after_filter :expire_caches, :only => [:update, :create, :destroy]
  caches_action :index, :expires_in => 30.minutes, :if => :cache_request?
  caches_action :show,  :expires_in => 30.minutes, :if => :cache_request?

  def index

    # Setup a search context for this tag: currently user or app
    if !params[:app].blank?
      @search_context = {:key => :application, :value => params[:app], :conditions => ["application = ? OR gml_application = ?",params[:app],params[:app]] }
    elsif !params[:user].blank?
      # Specifically customized for the secret_username using gml_uniquekey_hash trailing 5 digits! breakable coupling!
      @search_context = {:key => :user, :value => params[:user], :conditions => ["SUBSTRING(gml_uniquekey_hash, -5, 5) = ?", params[:user].gsub('anon-','')] }
    elsif !params[:location].blank?
      @search_context = {:key => :location, :value => params[:location], :conditions => ["location LIKE ?", params[:location]] }
    elsif !params[:keywords].blank?
      @search_context = {:key => :keywords, :value => params[:keywords], :conditions => "gml_keywords LIKE '%#{params[:keywords]}%'"}
    elsif !params[:user_id].blank?
      @user = User.find(params[:user_id])
      @search_context = {:key => :user, :value => @user.login, :conditions => ["user_id = ?",@user.id]}
    end

    @page, @per_page = params[:page] && params[:page].to_i || 1, 15
    @tags ||= Tag.paginate(:page => @page, :per_page => @per_page, :order => 'tags.created_at DESC', :include => [:user], :conditions => (@search_context && @search_context[:conditions]))
    @applications ||= Visualization.find_by_sql("SELECT DISTINCT application AS name FROM tags ORDER BY name")
    @applications.reject! { |app| app.name.blank? }

    set_page_title "GML Tags"+(@search_context ? ": #{@search_context[:key]}=#{@search_context[:value].inspect} " : '')

    # fresh_when :last_modified => @tags.first.updated_at.utc unless @tags.blank?
    #, :etag => @tags.first
    # expires_in 5.minutes, :public => true unless logged_in? # Rack::Cache
    respond_to do |wants|
      wants.html { render 'index' }
      wants.xml  { render :xml => @tags.to_xml(:dasherize => false, :except => Tag::HIDDEN_ATTRIBUTES, :skip_types => true) }
      wants.json { render :json => @tags.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback], :processingjs => params[:processingjs] }
      wants.rss  { render :rss => @tags }
    end
  end

  def show
    set_page_title "Tag ##{@tag.id}"

    # We only need these instance variables when rendering HTML (aka ghetto interlok)
     if params[:format] == 'html' || params[:format] == nil
      @prev = Tag.find(:last, :conditions => "id < #{@tag.id}")
      @next = Tag.find(:first, :conditions => "id > #{@tag.id}")

      @user = User.find(params[:user_id]) if params[:user_id]
      @user ||= @tag.user

      # No real comment pagination yet
      @comments = @tag.comments.visible.paginate(:page => params[:comments_page] || 1, :per_page => 10)

      # Some ghetto 'excludes' stripping until Tag after_save cleanup is working 100%
      @tag.gml.gsub!(/\<uniqueKey\>.*\<\/uniqueKey>/,'')
    end

    # fresh_when :last_modified => @tag.updated_at.utc, :etag => @tag
    respond_to do |wants|
      wants.html  { render }
      wants.gml   { render :xml => @tag.gml(:iphone_rotate => params[:iphone_rotate]) }
      wants.xml   { render :xml => @tag.to_xml(:except => Tag::HIDDEN_ATTRIBUTES, :dasherize => false, :skip_types => true) }
      wants.json  { render :json => @tag.to_json(:except => Tag::HIDDEN_ATTRIBUTES), :callback => params[:callback] }
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
  def random
    @tag = Tag.random
    redirect_to(tag_path(@tag), :status => 302) and return if [nil,'html'].include?(params[:format])
    show
  end


  # Create/edit tags
  def new
    set_page_title 'Upload a Graffiti Markup Language (GML) file'
    @tag = Tag.new
  end

  def edit
    set_page_title "Editing Tag ##{@tag.id}"
    render :action => 'new'
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

  # intended for canvasplayer dataURI callback
  def thumbnail
    if @tag.image.exists?
      render :text => 'thumbnail already exists', :status => 409 and return
    end
    @tag.image = params[:image]
    @tag.save!
    render :text => "OK", :status => 200, :layout => false
  rescue
    logger.error $!
    render :text => "Error: #{$!}", :status => 500
  end

  # add the 'mff2010' keyword for the Media Facades contest
  def nominate
    key = "mff2010"
    @tag.gml_keywords = (@tag.gml_keywords.blank? ? key : "#{@tag.gml_keywords},#{key}")
    if @tag.save
      flash[:notice] = "Tag #{@tag.id} nominated"
    else
      flash[:error] = "Error: #{$!}"
    end
    redirect_to(:back)
  end

  # interactive GML Syntax Validator
  # Actual processing -- accept /data/:id/validate but also accept raw data via POST
  def validate
    set_page_title "GML Syntax Validator"
    @noindex = true # Don't abuse this, Google

    if params[:id]
      @tag = Tag.find(params[:id])
    else
      @tag = Tag.new(params[:tag])
      @tag.gml = params[:gml] if @tag.gml.blank? && params[:gml]
    end
    @tag.validate_gml


    respond_to do |wants|
      wants.html {
        if request.xhr?
          render :text => @tag..validation_results.inspect
        else
          render 'validator'
        end
      }
      # TODO FIXME to_xml does the fuckin' <hash> thing :(
      wants.xml   { render :xml => @tag.validation_results.to_xml(:dasherize => false, :skip_types => true) }
      wants.json  { render :json => @tag.validation_results.to_json(:callback => params[:callback]) }
      wants.json  { render :text => @tag.validation_results.inspect }
    end
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
    # TODO add app uuid? or Hash app uuid?
    opts = {
      :gml => params[:gml],
      :ip => request.remote_ip,
      :location => params[:location],
      :application => params[:application],
      :remote_secret => params[:secret],
      :gml_uniquekey => params[:uniquekey],
      :image => params[:image]
    }

    # Merge opts & params to let people attempt to add whatever...
    @tag = Tag.new(opts)
    if @tag.save
      if params[:redirect] && ['true','1'].include?(params[:redirect].to_s)
        redirect_to(@tag, :status => 302) and return
      elsif !params[:redirect_back].blank? && !request.referer.blank?
        redirect_to(request.referer) and return
      elsif !params[:redirect_to].blank?
        redirect_to(params[:redirect_to]) and return
      else
        render :text => @tag.id, :status => 200 #OK
      end
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
  def convert_app_id_to_app_name
    # Sub in an existing application if specified...
    return unless params[:tag] && params[:tag][:existing_application_id] && params[:tag][:application].blank?

    # FIXME use internal ids if available? string matching all the time is ghetto
    app = Visualization.find(params[:tag][:existing_application_id]) rescue nil
    params[:tag][:application] = app.name unless app.blank?
  end

  # TODO this should be a Sweeper
  def expire_caches

    formats = [nil,'json','gml','xml','rss']

    # Tags#show
    if @tag && !@tag.new_record?
      formats.each { |format| expire_fragment(:controller => 'tags', :action => 'show', :id => @tag.id, :format => format) }
      Rails.cache.write(@tag.gml_hash_cache_key, @tag.convert_gml_to_hash) # Write-through object caching, but handling in the controller
    end

    # Tags#index
    formats.each { |format| expire_fragment(:controller => 'tags', :action => 'index', :format => format) }

    # Home#index -- FIXME which of these is correct?!
    expire_fragment(:controller => 'home', :action => 'index')
    expire_fragment('home/index')
  end


end
