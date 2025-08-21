require 'rails_helper'


describe FavoritesController do
  render_views

  before do
    activate_authlogic
    @user = FactoryBot.create(:user)
    @tag = FactoryBot.create(:tag)
  end

  describe "GET#index" do
    it "fails if not logged-in" do
      current_user_session.destroy
      expect { get :index }.to raise_error
    end

    it "should work with no user_id" do
      get :index
      expect(response).to be_successful
      expect(assigns(:user)).to eq(current_user)
    end

    it "should work with user_id but ignore it" do
      get :index, params: { user_id: @user.id }
      expect(response).to be_successful
      expect(assigns(:user)).to eq(current_user)
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
      post :create, params: { tag_id: @tag.id }
      expect(response).not_to be_successful
      expect(flash[:error]).not_to be_blank
    end

    it "should work" do
      login_as_user(@user)
      post :create, params: { tag_id: @tag.id }
      expect(response).to be_redirect
      expect(flash[:notice]).not_to be_blank
    end

    it "1st time should create a favorite" do
      login_as_user(@user)
      expect { post :create, params: { tag_id: @tag.id } }.to change(@user.favorites, :count).by(1)
      expect(flash[:notice]).not_to be_blank
    end

    it "2nd time should delete the favorite (unfavorite)" do
      login_as_user(@user)
      expect {
        post :create, params: { tag_id: @tag.id }
        post :create, params: { tag_id: @tag.id }
      }.to change(@user.favorites, :count).by(0)
      expect(flash[:notice]).not_to be_blank
    end
  end

end
