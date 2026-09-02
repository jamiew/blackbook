require 'rails_helper'

describe VisualizationsController do
  render_views

  before do
    @visualization = create(:visualization)
  end

  describe "GET #index" do
    it "routes from GET /apps" do
      { get: "/apps" }.should route_to("visualizations#index")
    end

    it "lists approved visualizations with pagination defaults" do
      @visualization.update!(approved_at: Time.current)
      get :index
      expect(response).to be_successful
      expect(assigns(:visualizations)).to be_present
      expect(assigns(:page)).to eq(1)
      expect(assigns(:per_page)).to eq(20)
    end

    it "renders an app that has no website" do
      @visualization.update!(approved_at: 1.hour.ago, website: nil)
      get :index
      expect(response).to be_successful
      expect(response.body).to include(@visualization.name)
    end

    it "narrows by language and by open source" do
      @visualization.update!(approved_at: 1.hour.ago, kind: 'javascript')
      closed = create(:visualization, approved_at: 1.hour.ago, kind: 'processing', source_url: nil)
      @visualization.update!(source_url: 'https://github.com/example/app')
      get :index, params: { kind: 'javascript' }
      expect(assigns(:visualizations)).to contain_exactly(@visualization)
      get :index, params: { source: 'open' }
      expect(assigns(:visualizations)).to contain_exactly(@visualization)
      expect(assigns(:visualizations)).not_to include(closed)
      expect(response.body).to match(/<a[^>]*aria-current="true"[^>]*>Open source</)
    end

    it "plays a tag made with the app on its card" do
      @visualization.update!(approved_at: 1.hour.ago)
      tag = create(:tag, application: @visualization.name)
      get :index
      expect(response.body).to include(%(data-preview="/data/#{tag.id}.json?preview=1"))
    end
  end

  describe "GET #show" do
    it "routes from GET /apps/:id" do
      { get: "/apps/1" }.should route_to("visualizations#show", id: "1")
    end

    it "renders the visualization name" do
      get :show, params: { id: @visualization.id }
      expect(response).to be_successful
      expect(response.body).to match(@visualization.name)
    end

    # /apps/1 in production has no website, and the view called gsub on it.
    it "renders an app that has no website" do
      @visualization.update!(website: nil)
      get :show, params: { id: @visualization.id }
      expect(response).to be_successful
    end

    it "plays the newest tag made with the app" do
      create(:tag, gml_application: @visualization.name)
      newest = create(:tag, application: @visualization.name)
      get :show, params: { id: @visualization.id }
      expect(assigns(:sample)).to eq(newest)
      expect(response.body).to include('data-gml-player')
    end

    it "404s if that record does not exist" do
      expect do
        Visualization.where(id: 666).first.should be_nil
        get :show, params: { id: 666 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #create" do
    before do
      @user = create(:user)
      login_as_user(@user)
    end

    it "routes from POST /apps" do
      { post: "/apps" }.should route_to("visualizations#create")
    end

    it "creates the visualization and redirects" do
      unique_name = "test_#{rand(100_000)}"
      expect do
        post :create,
             params: { visualization: { name: unique_name, description: 'test', authors: 'test', embed_url: 'test',
                                        source_url: 'https://github.com/example/app' } }
        expect(response).to be_redirect
        expect(Visualization.find_by(name: unique_name).source_url).to eq('https://github.com/example/app')
        expect(flash[:notice]).not_to be_blank
        expect(flash[:error]).to be_blank
      end.to change(Visualization, :count).by(1)
    end

    it "fails with no data" do
      expect do
        post :create
        expect(flash[:error]).not_to be_blank
      end.not_to change(Visualization, :count)
    end

    it "fails with bad data" do
      expect do
        post :create, params: { visualization: { name: 'other_fields_missing' } }
        expect(flash[:error]).not_to be_blank
      end.not_to change(Visualization, :count)
    end

    it "fails if you include HTML links" do
      expect do
        post :create, params: { visualization: { name: 'idk', authors: '<a href="me.com">it me</a>' } }
        expect(flash[:error]).not_to be_blank
      end.not_to change(Visualization, :count)
    end
  end
end
