class HomeController < ApplicationController
  
  def activity
    @notifications = Notification.latest
  end
end
