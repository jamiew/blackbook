class Admin::BaseController < ApplicationController
  layout 'admin'
  # before_filter :admin_required, :set_title
  before_filter :require_admin #Applies to all methods

  # ...

  private

  def set_title
    set_page_title('Admin')
  end

end
