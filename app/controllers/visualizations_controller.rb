class VisualizationsController < ApplicationController
  def index
    @page, @per_page = params[:page] || 1, 10
    @visualizations = Visualization.paginate(:page => @page, :per_page => @per_page)
  end
  
  def show
    @visualization = Visualization.find(params[:id])
  end
  
  # ...
end
