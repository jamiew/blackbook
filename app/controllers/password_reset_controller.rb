# frozen_string_literal: true

class PasswordResetController < ApplicationController
  before_action :load_user_using_perishable_token, only: %i[edit update]
  before_action :require_no_user

  def new
    set_page_title 'Forgot your password?'
  end

  def edit
    set_page_title 'Resetting your password'
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user.present?
      @user.deliver_password_reset_instructions!
      flash[:notice] = 'Instructions to reset your password have been emailed to you. ' \
                       'Please check your email.'
      redirect_to root_url
    else
      flash[:error] = 'No user was found with that email address'
      render action: :new
    end
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save
      flash[:notice] = 'Password successfully updated'
      redirect_to(user_path)
    else
      render action: :edit
    end
  end

  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    return unless @user.nil?

    flash[:notice] = "We're sorry, but we could not locate your account. " \
                     'If you are having issues try copying and pasting the URL ' \
                     'from your email into your browser or restarting the ' \
                     'reset password process.'
    redirect_to(root_url)
  end
end
