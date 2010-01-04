class FavoritesController < ApplicationController
  make_resourceful do
    actions :all
    
    response_for :show do |format|
      format.html
      format.xml { render :xml => @favorite }
    end
    response_for :index do |format|
      format.html
      format.xml { render :xml => @favorites }
    end
  end
end
