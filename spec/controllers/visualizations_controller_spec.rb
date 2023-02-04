require 'rails_helper'

describe VisualizationsController do
  render_views

  before do
    activate_authlogic
  end

  describe "GET #index" do
    it "routes from GET /apps" do
      { get: "/apps" }.should route_to("visualizations#index")
    end
    
    it "works" do
      pending 'TODO'
      fail
    end
  end

  describe "GET #show" do
    it "routes from GET /apps/:id" do
      { get: "/apps/1" }.should route_to("visualizations#show", id: 1)
    end

    it "works" do
      pending 'TODO'
      fail
    end

    it "404s if that record does not exist" do
      expect {
        Visualization.where(id: 666).first.should be_nil
        get :show, id: 666
      }.to_raise(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #create" do
    it "routes from POST /apps" do
      { post: "/apps" }.should route_to("visualizations#create")
    end

    it "works" do
      pending 'TODO'
      fail
    end

    it "fails with no data" do
      pending 'TODO'
      fail
    end

    it "fails with bad data" do
      pending 'TODO'
      fail
    end
  end

end
