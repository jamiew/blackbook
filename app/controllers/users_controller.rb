class UsersController < ApplicationController
  before_action :require_no_user, only: [:new, :create]
  before_action :require_user, only: [:edit, :change_password, :update]
  before_action :set_user_from_current_user, only: [:edit, :change_password, :update]

  # FIXME would love a smarter way to avoid test failures using this
  invisible_captcha only: [:create]

  # Show all users
  def index
    @page, @per_page = pagination_params(per_page: 28)
    @users = User.paginate(page: @page, per_page: @per_page)
    set_page_title "Users"
    # default_respond_to(@users, layout: true, exclude: [:email,:password,:crypted_password,:persistence_token])
  end

  # Show one user
  def show
    @user = User.find_by_param(params[:id])
    raise ActiveRecord::RecordNotFound if @user.nil?
    @page, @per_page = pagination_params(per_page: 10)

    @tags = @user.tags.order('created_at DESC').includes(:user).paginate(page: @page, per_page: @per_page)
    @notifications = @user.notifications.includes(:subject, :user).order('created_at DESC').paginate(page: 1, per_page: 15)

    set_page_title @user.name || @user.login

    respond_to do |format|
      format.html {}
    end
  end

  def new
    @user = User.new
  end

  def create
    user_params = user_parameters
    user_params[:password_confirmation] = user_params[:password] if user_params
    @user = User.new(user_params)
    if @user.save
      flash[:notice] = "Account registered!"
      UserMailer.signup_notification(@user).deliver_now
      redirect_back_or_default(user_path(@user))
    else
      render action: :new
    end
  end

  def edit
    set_page_title "Your Settings"
  end

  def update
    if @user.update(user_parameters)
      flash[:notice] = "Settings updated! "
      redirect_to(settings_path)
    else
      # Errors printed to form
      render action: :edit
    end
  end


private

  def user_parameters
    params.require(:user).permit(:login, :email, :password, :password_confirmation, :name, :iphone_uniquekey, :photo, :location, :website, :about)
  end

protected

  def set_user_from_current_user
    @user = @current_user  # makes our views "cleaner" and more consistent
  end

end
