class HomeController < ApplicationController
  
  def index
    @tags = Tag.find(:all, :order => 'created_at DESC', :limit => 7)
    @users = User.find(:all, :order => 'created_at DESC', :limit => 10)
  end
  
  def activity
    @page, @per_page = params[:page] || 1, 20
    @notifications = Notification.paginate(:page => @page, :per_page => @per_page, :order => 'created_at DESC')
  end
  
  # Show a single static file
  # FIXME -- hardcoded references to haml & erb
  def static
    if (File.exist?("#{RAILS_ROOT}/app/views/pages/#{params[:id]}.html.haml") || File.exist?("#{RAILS_ROOT}/app/views/pages/#{params[:id]}.html.erb"))
      render :template => "pages/#{params[:id]}"
    else
      render :file => "public/404.html"
    end
  end
  
end
