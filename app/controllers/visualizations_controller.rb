class VisualizationsController < ApplicationController
  before_action :get_visualization, only: %i[show edit update destroy approve unapprove]
  before_action :require_admin, only: %i[approve unapprove]
  before_action :require_owner, only: %i[edit update destroy]
  before_action :require_user, only: %i[new create]

  respond_to :html, :js, :xml, :json

  def index
    set_page_title "GML Applications"
    current_objects
  end

  def show
    set_page_title "#{@visualization.name}, a GML application"
    @sample = sample_tags([@visualization.name])[@visualization.name]
    respond_with @visualization do |format|
      format.html {}
      format.js
      format.xml
    end
  end

  def new
    set_page_title "Creating new application"
    @visualization = Visualization.new
  end

  def edit
    @visualization = Visualization.find(params[:id])
    set_page_title "Editing app #{@visualization.id}"
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

  def update
    if @visualization.update(visualization_parameters)
      flash[:notice] = "Application updated"
      redirect_to visualization_path(@visualization)
    else
      flash[:error] = "Errors updating application"
      render :edit
    end
  end

  # Approve/reject an entry
  def approve
    update_approval_state(@visualization, true)
    flash[:notice] = "App was approved!"
    redirect_back_or_default(@visualization)
  end

  def unapprove
    update_approval_state(@visualization, false)
    flash[:notice] = "App was unapproved"
    redirect_back_or_default(@visualization)
  end

  protected

  def get_visualization
    @visualization = Visualization.find(params[:id])
  end

  def current_objects
    @page, @per_page = pagination_params
    which = is_admin? ? Visualization : Visualization.approved
    # A kind gets a chip only if something listed is written in it. Read before
    # the filters below, so a chip never disappears because you are standing on it.
    kinds = which.distinct.pluck(:kind)
    @kinds = Visualization::KINDS.select { |_, value| value.present? && kinds.include?(value) }
    if params[:user_id]
      @user = User.find_by_param(params[:user_id])
      which = which.where(user_id: @user.id)
    end
    @visualizations ||= chipped(which).with_attached_image.includes(:user)
                                      .order(approved_at: :desc, name: :asc)
                                      .paginate(page: @page, per_page: @per_page)
    @samples = sample_tags(@visualizations.map(&:name))
  end

  # The chips. They combine: ?kind=javascript&source=open.
  def chipped(scope)
    scope = scope.where(kind: params[:kind]) if params[:kind].present?
    scope = scope.open_source if params[:source] == 'open'
    scope = scope.where(is_embeddable: true) if params[:embeddable].present?
    scope
  end

  # The newest tag made with each app, by name, so a card can play one. Tags
  # name their app in either of two columns. One LIMIT 1 per app: an app like
  # DustTag has tens of thousands of tags, and loading them to pick one is not
  # an option.
  def sample_tags(names)
    names.index_with do |name|
      Tag.where(application: name).or(Tag.where(gml_application: name)).order(created_at: :desc, id: :desc).first
    end.compact
  end

  def update_approval_state(obj, enabled)
    obj.approved_at = (enabled ? Time.zone.now : nil)
    obj.approved_by = (enabled ? current_user.id : nil)
    obj.save!
  end

  def require_owner
    raise NoPermissionError unless current_user && (@visualization.user == current_user || is_admin?)
  end

  private

  def visualization_parameters
    params.fetch(:visualization, {}).permit(:name, :version, :description, :authors, :website, :source_url, :kind,
                                            :image, :is_embeddable, :embed_url, :embed_callback, :embed_params,
                                            :embed_code)
  end
end
