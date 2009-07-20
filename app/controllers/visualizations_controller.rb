class VisualizationsController < ApplicationController
  def index
    @visualizations = Visualization.all
  end
  
  def show
    @visualization = Visualization.find(params[:id])
  end
  
  # ...
end
