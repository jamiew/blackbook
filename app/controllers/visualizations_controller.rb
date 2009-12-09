class VisualizationsController < ApplicationController
  before_filter :require_user, :only => [:new, :create, :edit, :update]
  before_filter :setup_user, :only => [:create] # Not update
  
  make_resourceful do
    actions :all
    belongs_to :user

    response_for :show do |format|
      format.html
      format.js
      format.xml
    end

    # response_for :update_fails do |format|
    #   format.html { render :action => 'edit' }
    #   format.json { render :json => false.to_json, :status => 422 }
    # end
    
  end  
  
  private
  
  def setup_user
    #Or should we set this on the object? This overrides accidental form input as well
    params[:user_id] = current_user
  end
  
end
