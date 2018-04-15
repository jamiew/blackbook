require 'rails_helper'


describe FavoritesController do
  render_views

  before do
    activate_authlogic
    @user = FactoryBot.create(:user)
    @tag = FactoryBot.create(:tag)
  end

  describe "GET#index" do
    it "should 404 with no user_id" do
      lambda { get :index }.should raise_error
    end

    it "should work with a user_id" do
      get :index, :user_id => @user.id
      response.should be_success
    end
  end

  describe "POST #create" do
    before do
      @user = FactoryBot.create(:user)
      request.env["HTTP_REFERER"] = tag_path(@tag)
      # FIXME we're relying on redirect_to(:back) inside FavoritesController...
    end

    it "should fail if not logged-in" do
      current_user_session.destroy
      post :create, :tag_id => @tag.id
      response.should_not be_success
      flash[:error].should_not be_blank
    end

    it "should work" do
      login_as_user(@user)
      post :create, :tag_id => @tag.id
      response.should be_redirect
      flash[:notice].should_not be_blank
    end

    it "1st time should create a favorite" do
      login_as_user(@user)
      lambda { post :create, :tag_id => @tag.id }.should change(@user.favorites, :count).by(1)
      flash[:notice].should_not be_blank
    end

    it "2nd time should delete the favorite (unfavorite)" do
      login_as_user(@user)
      lambda {
        post :create, :tag_id => @tag.id
        post :create, :tag_id => @tag.id
      }.should change(@user.favorites, :count).by(0)
      flash[:notice].should_not be_blank
    end
  end

end
