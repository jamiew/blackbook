class VisualizationsController < ApplicationController
  before_filter :require_owner, :only => [:edit, :update, :destroy]
  before_filter :require_user, :only => [:new, :create]
  before_filter :setup_user, :only => [:create] # Not update
  
  make_resourceful do
    actions :all

    response_for :show do |format|
      format.html
      format.js
      format.xml
    end

    # response_for :update_fails do |format|
    #   format.html { render :action => 'edit' }
    #   format.json { render :json => false.to_json, :status => 422 }
    # end    
    
    def current_objects
      @page, @per_page = params[:page] || 1, 20
      @current_objects ||= current_model.paginate(:page => @page, :per_page => @per_page)
    end
  end  
  
private
  
  def setup_user
    #Or should we set this on the object? This overrides accidental form input as well
    params[:user_id] = current_user
  end
  
  def require_owner #FIXME; convert to a global current_object.user/.owner ghetto permissions model
    puts "... current_user=#{current_user.inspect} is_admin?=#{is_admin?}"
    raise "You don't have permission to do this" unless current_user && (current_object.user == current_user || is_admin?)
  end
  
end
