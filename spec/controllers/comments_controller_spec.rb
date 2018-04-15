require 'rails_helper'


describe CommentsController do
  render_views

  before do
    activate_authlogic
    @tag = FactoryBot.create(:tag)
  end

  describe "GET#index" do
    it "should fail with no parent association" do
      lambda { get :index }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should work with a parent Tag" do
      get :index, :tag_id => @tag.id
      response.should be_success
    end

    it "should work with a parent User" do
      @user = FactoryBot.create(:user)
      get :index, :user_id => @user.id
      response.should be_success
    end
  end

  it "POST #create should work" do
    login_as_user
    post :create, :tag_id => @tag.id, :comment => {:text => 'Lolcats R awesome'}
  end

  describe "DELETE#destroy" do
    before do
      @comment = FactoryBot.create(:comment)
    end

    it "should work for admins" do
      login_as_admin
      delete :destroy, :tag_id => @tag.id, :id => @comment.id
      Comment.find(@comment.id).hidden?.should == true
      response.should be_redirect
    end

    it "should work for the comment owner" do
      login_as_user(@comment.user)
      delete :destroy, :tag_id => @tag.id, :id => @comment.id
      Comment.find(@comment.id).hidden?.should == true
      response.should be_redirect
    end

    it "should fail for non-owner users" do
      login_as_user
      delete :destroy, :tag_id => @tag.id, :id => @comment.id
      response.status.should == 403 # Forbidden
    end

    it "should fail for logged-out users" do
      delete :destroy, :tag_id => @tag.id, :id => @comment.id
      response.status.should == 403 # Forbidden
    end
  end

end
