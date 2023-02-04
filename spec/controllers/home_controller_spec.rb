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
    expect(response.body).to match(/an open database for Graffiti Markup Language/)
    expect(response).to be_success
  end

  it "/about works" do
    get :about
    expect(response.body).to match(/About/)
    expect(response).to render_template('home/about')
    expect(response).to be_success
  end
end
