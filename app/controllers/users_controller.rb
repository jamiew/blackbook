class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:edit, :change_password, :update]
  before_filter :set_user_from_current_user, :only => [:edit, :change_password, :update]

  # Show all users
  def index
    @page, @per_page = params[:page] || 1, 20
    @users = User.paginate(:page => @page, :per_page => @per_page)
    puts @users.inspect
    # default_respond_to(@users, :layout => true, :exclude => [:email,:password,:crypted_password,:persistence_token])
  end
  
  # Show one user
  def show
    @page, @per_page = params[:page] || 1, 10
    @user = User.find(params[:id])    
    @tags = @user.tags.paginate(:page => @page, :per_page => @per_page)
  end

  # Setup a new user
  def new
    @user = User.new
  end
  
  def create
    params[:user][:password_confirmation] = params[:user][:password] if params[:user]
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default(user_path(@user))
    else
      render :action => :new
    end
  end

  # Change information about ourselves
  def edit
  end

  def change_password
  end

  def update
    puts params.inspect
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to(user_path(@user))
    else
      # Errors printed to form
      render :action => :edit
    end
  end
  
  
  protected
  
  def set_user_from_current_user
    @user = @current_user  # makes our views "cleaner" and more consistent
  end
  
end
