require 'rails_helper'


describe HomeController do
  render_views

  before do
    activate_authlogic
    @tag = FactoryGirl.create(:tag)
  end

  it "/ works" do
    get :index
    response.should be_success
    response.body.should match(/an open database for Graffiti Markup Language/)
  end

  it "/about works" do
    get :about
    response.should be_success
    response.body.should match(/About/)
    response.should render_template('home/about')
  end
end
