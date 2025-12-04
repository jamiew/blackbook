require 'rails_helper'

describe VisualizationsController do
  render_views

  before do
    activate_authlogic
    @visualization = create(:visualization)
  end

  describe "GET #index" do
    it "routes from GET /apps" do
      { get: "/apps" }.should route_to("visualizations#index")
    end

    it "works" do
      @visualization.update!(approved_at: Time.current)
      get :index
      expect(response).to be_successful
      expect(assigns(:visualizations)).to be_present
      expect(assigns(:page)).to eq(1)
      expect(assigns(:per_page)).to eq(20)
    end
  end

  describe "GET #show" do
    it "routes from GET /apps/:id" do
      { get: "/apps/1" }.should route_to("visualizations#show", id: "1")
    end

    it "works" do
      get :show, params: { id: @visualization.id }
      expect(response).to be_successful
      expect(response.body).to match(@visualization.name)
    end

    it "404s if that record does not exist" do
      expect {
        Visualization.where(id: 666).first.should be_nil
        get :show, params: { id: 666 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #create" do
    before do
      @user = create(:user)
      UserSession.create(@user)
    end

    it "routes from POST /apps" do
      { post: "/apps" }.should route_to("visualizations#create")
    end

    it "works" do
      unique_name = "test_#{rand(100000)}"
      expect {
        post :create, params: { visualization: { name: unique_name, description: 'test', authors: 'test', embed_url: 'test' } }
        expect(response).to be_redirect
        expect(flash[:notice]).not_to be_blank
        expect(flash[:error]).to be_blank
      }.to change(Visualization, :count).by(1)
    end

    it "fails with no data" do
      expect {
        post :create
        expect(flash[:error]).to_not be_blank
      }.to_not change(Visualization, :count)
    end

    it "fails with bad data" do
      expect {
        post :create, params: { visualization: { name: 'other_fields_missing' } }
        expect(flash[:error]).to_not be_blank
      }.to_not change(Visualization, :count)
    end

    it "fails if you include HTML links" do
      expect {
        post :create, params: { visualization: { name: 'idk', authors: '<a href="me.com">it me</a>' } }
        expect(flash[:error]).to_not be_blank
      }.to_not change(Visualization, :count)
    end
  end

end
