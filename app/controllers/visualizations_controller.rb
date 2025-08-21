class VisualizationsController < ApplicationController

  before_action :get_visualization, only: [:show, :edit, :update, :destroy, :approve, :unapprove]
  before_action :require_admin, only: [:approve, :unapprove]
  before_action :require_owner, only: [:edit, :update, :destroy]
  before_action :require_user, only: [:new, :create]

  respond_to :html, :js, :xml, :json

  def show
    set_page_title @visualization.name
    respond_with @visualization do |format|
      format.html {}
      format.js
      format.xml
    end
  end

  def index
    set_page_title "GML Applications"
    @visualizations = Visualization.paginate(page: @page, per_page: @per_page).order('created_at ASC')
  end

  def new
    set_page_title "Creating new application"
    @visualization = Visualization.new
  end

  def create
    @visualization = current_user.visualizations.new(visualization_parameters)
    respond_with @visualization do |format|
      format.html do
        if @visualization.save
          flash[:notice] = "Application created"
          redirect_to visualization_path(@visualization)
        else
          flash[:error] = "Errors creating application"
          render :new
        end
      end
    end
  end

  def edit
    @visualization = Visualization.find(params[:id])
    set_page_title "Editing app #{@visualization.id}"
  end

  def update
    raise 'TODO'
  end

  # Approve/reject an entry
  def approve
    update_approval_state(@visualization, true)
    flash[:notice] = "App was approved!"
    redirect_back_or_default(@visualization)
  end

  # DRY?
  def unapprove
    update_approval_state(@visualization, false)
    flash[:notice] = "App was unapproved"
    redirect_back_or_default(@visualization)
  end

protected

  def get_visualization
    @visualization = Visualization.find(params[:id])
  end

  # FIXME these date back to using some magic super controller class magic
  def current_objects
    @page = params[:page] && params[:page].to_i || 1
    @per_page = 20
    which = is_admin? ? current_model : current_model.approved
    if params[:user_id]
      @user = User.find_by_param(params[:user_id])
      which = which.by_user(@user.id)
      #TODO: set page_title etc. Also handle all this logic less if/elsify
    end
    @visualizations ||= which.paginate(page: @page, per_page: @per_page, include: [:user], order: 'approved_at DESC, name ASC')
  end

  def update_approval_state(obj, enabled)
    logger.debug "hi from update_approval_state obj=#{obj.inspect}"
    obj.approved_at = (enabled ? Time.now : nil)
    obj.approved_by = (enabled ? current_user.id : nil)
    obj.save!
  end

  def require_owner
    raise NoPermissionError unless current_user && (@visualization.user == current_user || is_admin?)
  end

  private

  def visualization_parameters
    params.fetch(:visualization, {}).permit(:name, :description, :authors, :website, :embed_url, :kind, :is_embeddable, :image)
  end
end
