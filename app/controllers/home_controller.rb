class HomeController < ApplicationController
  
  def index
    @tags = Tag.find(:all, :order => 'created_at DESC', :limit => 12)
    @users = User.find(:all, :order => 'created_at DESC', :limit => 10)
  end
  
  def activity
    @notifications = Notification.latest
  end
end
