class Admin::BaseController < ApplicationController
  layout 'admin'
  before_filter :require_admin

  def index
  end

private

  def set_title
    set_page_title('Admin')
  end

end
