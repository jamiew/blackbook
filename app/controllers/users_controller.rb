class UsersController < ApplicationController
  before_filter :require_no_user, only: [:new, :create]
  before_filter :require_user, only: [:edit, :change_password, :update]
  before_filter :set_user_from_current_user, only: [:edit, :change_password, :update]

  force_ssl

  invisible_captcha only: [:create]

  # Show all users
  def index
    @page, @per_page = params[:page] && params[:page].to_i || 1, 28
    @users = User.paginate(page: @page, per_page: @per_page)
    set_page_title "Users"
    # default_respond_to(@users, layout: true, exclude: [:email,:password,:crypted_password,:persistence_token])
  end

  # Show one user
  def show
    @user = User.find_by_param(params[:id])
    raise ActiveRecord::RecordNotFound if @user.nil?
    @page, @per_page = params[:page] && params[:page].to_i || 1, 10

    @tags = @user.tags.includes(:user).paginate(page: @page, per_page: @per_page)
    @wall_posts = @user.wall_posts.includes(:user).order('created_at DESC').paginate(page: 1, per_page: 10)
    @notifications = @user.notifications.includes(:subject, :user).order('created_at DESC').paginate(page: 1, per_page: 15)

    set_page_title @user.name || @user.login
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
      Mailer.signup_notification(@user).deliver
      redirect_back_or_default(user_path(@user))
    else
      render action: :new
    end
  end

  # Change information about ourselves
  def edit
    set_page_title "Your Settings"
  end

  def change_password
    #TODO? ack
  end

  def update
    @user.attributes = params[:user]

    if @user.update_attributes(params[:user])
      flash[:notice] = "Settings updated! "
      redirect_to(settings_path)
    else
      # Errors printed to form
      render action: :edit
    end
  end


protected

  def set_user_from_current_user
    @user = @current_user  # makes our views "cleaner" and more consistent
  end

end
