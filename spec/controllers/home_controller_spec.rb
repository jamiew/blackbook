require 'rails_helper'


describe HomeController do
  require 'rails_helper'


  before do
    activate_authlogic
    @tag = Factory(:tag) # Act like we've got at least 1 tag
  end

  it "/ (homepage) should work" do
    get :index
    response.should be_success
    response.body.should match(/an open database for Graffiti Markup Language/)
  end

  # TODO test that "/about" routes to Home#static

  it "/about should work" do
    get :static, :id => 'about'
    response.should be_success
    response.body.should match(/About/)
    response.should render_template('pages/about')
  end

  it "should 404 on a bad page ID" do
    get :static, :id => 'fake_bad_page'
    response.status == "404 Not Found"
  end
end
