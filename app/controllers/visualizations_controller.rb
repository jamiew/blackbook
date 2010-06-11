class VisualizationsController < ApplicationController

  before_filter :setup_user, :only => [:create] # Not update
  before_filter :require_admin, :only => [:approve, :unapprove]
  before_filter :require_owner, :only => [:edit, :update, :destroy]
  before_filter :require_user, :only => [:new, :create]

  make_resourceful do
    actions :all
    belongs_to :user

    response_for :show do |format|
      format.html
      format.js
      format.xml
    end

    before :index do
      set_page_title "Applications"
    end

    before :show do
      set_page_title @visualization.name
    end

    response_for :create do |format| # Don't use nested route
      format.html { flash[:notice] = "Application submitted"; redirect_to visualization_path(current_object) }
    end

    # response_for :update_fails do |format|
    #   format.html { render :action => 'edit' }
    #   format.json { render :json => false.to_json, :status => 422 }
    # end

  end

  def current_objects
    @page, @per_page = params[:page] && params[:page].to_i || 1, 20
    which = is_admin? ? current_model : current_model.approved
    if params[:user_id]
      @user = User.find(params[:user_id]) rescue nil
      which = which.by_user(@user.id)
      #TODO: set page_title etc. Also handle all this logic less if/elsify
    end
    @visualizations ||= which.paginate(:page => @page, :per_page => @per_page, :include => [:user], :order => 'approved_at DESC, name ASC')
  end


  # Approve/reject an entry
  def approve
     update_approval_state(current_object, true)
    flash[:notice] = "App was approved!"
    redirect_back_or_default(current_object)
  end

  # DRY?
  def unapprove
    update_approval_state(current_object, false)
    flash[:notice] = "App was unapproved"
    redirect_back_or_default(current_object)
  end

  protected

    def update_approval_state(obj, enabled)
      current_object.approved_at = (enabled ? Time.now : nil)
      current_object.approved_by = (enabled ? current_user.id : nil)
      current_object.save!
    end

  private

    def setup_user
      #Or should we set this on the object? This overrides accidental form input as well
      params[:visualization][:user_id] = params[:user_id] = current_user.id
    end

    def require_owner #FIXME; convert to a global current_object.user/.owner ghetto permissions model
      raise NoPermissionError unless current_user && (current_object.user == current_user || is_admin?)
    end

end
