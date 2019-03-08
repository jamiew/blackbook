require 'rails_helper'


describe HomeController do
  render_views

  before do
    request.env["rack.url_scheme"] = "https"
  end

  before do
    activate_authlogic
    @tag = FactoryBot.create(:tag)
  end

  it "/ works" do
    get :index
    response.body.should match(/an open database for Graffiti Markup Language/)
    response.should be_success
  end

  it "/about works" do
    get :about
    response.body.should match(/About/)
    response.should render_template('home/about')
    response.should be_success
  end
end
