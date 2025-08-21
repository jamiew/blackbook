require 'ostruct'

class TagsController < ApplicationController

  # We allow open access to API #create -- no authentication or forgery protection
  protect_from_forgery except: [:show, :latest, :random, :create, :thumbnail, :validate]
  before_action :get_tag, only: [:show, :edit, :update, :destroy, :thumbnail, :nominate]
  before_action :require_user, only: [:new, :edit, :update, :destroy, :nominate]
  before_action :require_owner, only: [:edit, :update, :destroy]
  before_action :convert_app_id_to_app_name, only: [:update, :create]

  # Basic caching for :index?page=1 and :show actions
  after_action :expire_caches, only: [:update, :create, :destroy]
  # caches_action :index, expires_in: 30.minutes, if: :cache_request?
  # caches_action :show,  expires_in: 30.minutes, if: :cache_request?

  def index

    # Setup a search context for this tag: currently user or app
    if !params[:app].blank?
      @search_context = {key: :application, value: params[:app], conditions: ["application = ? OR gml_application = ?",params[:app],params[:app]] }
    elsif !params[:user].blank?
      # Specifically customized for the secret_username using gml_uniquekey_hash trailing 5 digits! breakable coupling!
      @search_context = {key: :user, value: params[:user], conditions: ["SUBSTRING(gml_uniquekey_hash, -5, 5) = ?", params[:user].gsub('anon-','')] }
    elsif !params[:location].blank?
      @search_context = {key: :location, value: params[:location], conditions: ["location LIKE ?", params[:location]] }
    elsif !params[:keywords].blank?
      @search_context = {key: :keywords, value: params[:keywords], conditions: ["gml_keywords LIKE ?", params[:keywords]]}
    elsif !params[:user_id].blank?
      @user = User.find_by_param(params[:user_id])
      raise ActiveRecord::RecordNotFound if @user.blank?
      @search_context = {key: :user, value: @user.login, conditions: ["user_id = ?",@user.id]}
    end

    @page = params[:page] && params[:page].to_i || 1
    if @page < 1
      flash[:error] = "Invalid page number specified"
      redirect_to tags_path and return
    end

    @per_page = 15
    @tags ||= Tag.order('tags.created_at DESC').includes(:user).where(@search_context && @search_context[:conditions]).paginate(page: @page, per_page: @per_page)
    @applications ||= Tag.select("DISTINCT application AS name").order("name").where.not(application: [nil, ""]).map { |t| OpenStruct.new(name: t.name) }
    @applications.reject! { |app| app.name.blank? }

    set_page_title "GML Tags"+(@search_context ? ": #{@search_context[:key]}=#{@search_context[:value].inspect} " : '')

    # fresh_when last_modified: @tags.first.updated_at.utc unless @tags.blank?
    #, etag: @tags.first
    # expires_in 5.minutes, public: true unless logged_in? # Rack::Cache
    respond_to do |wants|
      wants.html { render 'index' }
      wants.xml  { render xml: @tags.to_xml(dasherize: false, except: Tag::HIDDEN_ATTRIBUTES, skip_types: true) }
      wants.json { render json: @tags.to_json(except: Tag::HIDDEN_ATTRIBUTES), callback: params[:callback], processingjs: params[:processingjs] }
      wants.rss  { render rss: @tags }
    end
  end

  def show
    set_page_title "Tag ##{@tag.id}"

    # We only need these instance variables when rendering HTML (aka ghetto interlok)
     if params[:format] == 'html' || params[:format] == nil
      @prev = Tag.where("id < ?", @tag.id).last
      @next = Tag.find_by("id > ?", @tag.id)

      @user = User.find_by_param(params[:user_id]) if params[:user_id]
      @user ||= @tag.user

      # No real comment pagination yet
      @comments = @tag.comments.visible.paginate(page: params[:comments_page] || 1, per_page: 10)

      # Some ghetto 'excludes' stripping until Tag after_save cleanup is working 100%
      # FIXME wow. just wow.
      @tag.gml && @tag.gml.gsub!(/\<uniqueKey\>.*\<\/uniqueKey>/,'')
    end

    # Freak out if GML data is missing; this really isn't ever supposed to happen
    raise MissingDataError if @tag.gml.blank?

    # fresh_when last_modified: @tag.updated_at.utc, etag: @tag
    respond_to do |wants|
      wants.html  { render }
      wants.gml   { render xml: @tag.gml(iphone_rotate: params[:iphone_rotate]) }
      wants.xml   { render xml: @tag.to_xml(except: Tag::HIDDEN_ATTRIBUTES, dasherize: false, skip_types: true) }
      wants.json  {
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response['Access-Control-Max-Age'] = '1728000'
        render json: @tag.to_json(except: Tag::HIDDEN_ATTRIBUTES), callback: params[:callback]
      }
    end
  end

  # Quick accessor to grab the latest tag -- great for running installations with the freshest GML
  # Hand off to :show except for HTML, which should redirect -- keep permalinks happy
  def latest
    @tag = Tag.order('created_at DESC').first
    redirect_to(tag_path(@tag), status: 302) and return if [nil,'html'].include?(params[:format])
    show
  end

  # Just a random tag -- redirect to canonical for HTML, but otherwise don't bother (API)
  def random
    require 'activerecord_random' # FIXME rails5 no longer autoloading the lib/ directory
    @tag = Tag.random
    redirect_to(tag_path(@tag), status: 302) and return if [nil,'html'].include?(params[:format])
    show
  end

  # Create/edit tags
  def new
    set_page_title 'Upload a Graffiti Markup Language (GML) file'
    @tag = Tag.new
  end

  def edit
    set_page_title "Editing Tag ##{@tag.id}"
    render action: 'new'
  end

  # Calls either create_from_form (on-site, more strict) or create_from_api (less strict)
  def create
    if params.blank?
      logger.warn "no params"
      raise "No params!"
    end

    if params[:check] == 'connected' #DustTag weirdness?
      logger.debug "connected check"
      head :ok
      return
    end

    if !params[:tag].blank? # sent by the form
      logger.debug "sent by the form"
      return create_from_form
    elsif !params[:gml].blank? # sent from an app!
      logger.debug "sent from an app"
      return create_from_api
    else
      # Otherwise error out, without displaying any sensitive or internal params
      error_text = "Error, could not create tag from your parameters: #{clean_params.inspect}"
      logger.warn error_text
      render plain: error_text, status: 422 #Unprocessable Entity
      return
    end

    expire_page(:index)
  end

  def update
    @tag.update(params[:tag].permit(:gml, :gml_file, :application, :description, :location, :image, :existing_application_id))
    if @tag.save
      flash[:notice] = "Tag ##{@tag.id} updated"
      redirect_to tag_path(@tag)
    else
      flash[:error] = "Could not update tag: #{$!}"
      render action: 'edit'
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
    redirect_back(fallback_location: root_path)
  end

  # Upload an image for a tag if one doesn't already exist (for GMLImageRenderer)
  def thumbnail
    if @tag.image.exists?
      render plain: 'thumbnail already exists', status: 409 and return
    end
    @tag.image = params[:image]
    @tag.save!
    render plain: "OK", status: 200, layout: false
  rescue
    logger.error $!
    render plain: "Error: #{$!}", status: 500
  end

  # Interactive GML Syntax Validator
  def validate
    if params[:id]
      @tag = Tag.find(params[:id])
    elsif params[:tag] && params[:tag][:id]
      @tag = Tag.find(params[:tag][:id])
    else
      @tag = Tag.new(params[:tag]&.permit(:gml, :gml_file, :application, :description, :location, :image, :existing_application_id) || {})
      @tag.gml = params[:gml] if @tag.gml.blank? && params[:gml]
    end
    @tag.validate_gml

    set_page_title "GML Syntax Validator"
    @noindex = true unless @tag.gml.blank?

    respond_to do |wants|
      wants.html {
        if request.xhr?
          render plain: @tag..validation_results.inspect
        else
          render 'validator'
        end
      }
      # FIXME to_xml does the fuckin' <hash> thing :(
      joined_hash = Hash[@tag.validation_results.map { |k,v| [k, v.join(";\n")] }]
      wants.xml   { render xml: joined_hash.to_xml(dasherize: false, skip_types: true) }
      wants.json  { render json: @tag.validation_results.to_json(callback: params[:callback]) }
      wants.xhr   { render plain: @tag.validation_results.map{|k,v| "#{k}=#{v.join(',') || 'none'}"}.join("\n") }
      wants.text  { render plain: @tag.validation_results.map{|k,v| "#{k}=#{v.join(',') || 'none'}"}.join("\n") }
    end
  end



protected

  def get_tag
    @tag = Tag.find(params[:id])
  end

  def require_owner
    logger.debug "require_owner (tag.id=#{@tag.id rescue nil}): current_user=#{current_user.id rescue nil}; tag.user.id=#{@tag.user.id rescue nil}"
    raise NoPermissionError unless current_user && @tag && (@tag.user == current_user || is_admin?)
  end

  # Create a tag uploaded w/o a user or authentication, via the ghetto-API
  # this is currently used for tempt from the Eyewriter, but will be expanded...
  def create_from_api
    # TODO add app uuid? or Hash app uuid?
    opts = {
      gml: params[:gml],
      ip: request.remote_ip,
      location: params[:location],
      application: params[:application],
      remote_secret: params[:secret],
      gml_uniquekey: params[:uniquekey],
      image: params[:image]
    }

    # Merge opts & params to let people attempt to add whatever...
    @tag = Tag.new(opts)
    if @tag.save
      if params[:redirect] && ['true','1'].include?(params[:redirect].to_s)
        redirect_to(@tag, status: 302) and return
      elsif !params[:redirect_back].blank? && !request.referer.blank?
        redirect_to(request.referer, allow_other_host: true) and return
      elsif !params[:redirect_to].blank?
        redirect_to(params[:redirect_to], allow_other_host: true) and return
      else
        render plain: @tag.id, status: 200 #OK
      end
    else
      logger.error "Could not create tag from API... Tag: #{@tag.errors.full_messages.inspect}\nGMLObject#{@tag.gml_object.inspect}"
      render plain: "ERROR: #{@tag.errors.inspect}", status: 422 # Unprocessable Entity
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
      logger.debug "Reading from GML file = #{file.inspect}"
      params[:tag][:gml] = file.read
    end

    # Build object with permitted params
    @tag = Tag.new(params[:tag].permit(:gml, :gml_file, :application, :description, :location, :image, :existing_application_id, :user))

    # GML data of some kind is required -- catching this ourselves due to GmlObject complexity...
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
    render action: 'new', status: 422 #Unprocessable entity
  end

  # For converting from the pre-existing 'Application' params into a string in create/update
  def convert_app_id_to_app_name
    Rails.logger.debug "#convert_app_id_to_app_name"

    # Sub in an existing application if specified...
    return unless params[:tag] && params[:tag][:existing_application_id] && params[:tag][:application].blank?

    # FIXME use internal ids if available? string matching all the time is ghetto
    app = Visualization.find(params[:tag][:existing_application_id]) rescue nil
    params[:tag][:application] = app.name unless app.blank?
  end

  # TODO this should be a Sweeper...
  def expire_caches
    formats = [nil,'json','gml','xml','rss','txt']

    # Tags#show
    if @tag && !@tag.new_record?
      formats.each { |format| expire_fragment(controller: 'tags', action: 'show', id: @tag.id, format: format) }
      # Write-through(ish) object caching of the raw GML
      Rails.cache.write(@tag.gml_hash_cache_key, @tag.convert_gml_to_hash)
    end

    # Tags#index
    formats.each { |format| expire_fragment(controller: 'tags', action: 'index', format: format) }

    # Home#index -- FIXME which of these is correct?!
    expire_fragment(controller: 'home', action: 'index')
    expire_fragment('home/index')
  end

  private

  def tag_parameters
    params.require(:tag).permit(:gml, :gml_file, :application, :description, :location, :image, :existing_application_id)
  end

end
