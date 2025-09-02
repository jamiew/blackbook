require 'rails_helper'


describe HomeController do
  render_views

  before do
    request.env["rack.url_scheme"] = "https"
  end

  before do
    activate_authlogic
  end

  it "/ works" do
    get :index
    expect(response.body).to match(/an open database for Graffiti Markup Language/)
    expect(response).to be_successful
  end

  it "/about works" do
    get :about
    expect(response.body).to match(/About/)
    expect(response).to render_template('home/about')
    expect(response).to be_successful
  end

  describe "pagination parameter validation" do
    # Test the controller logic without hitting the views
    controller HomeController do
      def test_safe_page_param
        @page = safe_page_param(params[:page])
        render plain: @page.to_s
      end
    end

    before do
      routes.draw { get 'test_safe_page_param' => 'home#test_safe_page_param' }
    end

    it "handles malicious page parameters safely" do
      get :test_safe_page_param, params: { page: "'" }
      expect(response.body).to eq("1")
    end

    it "handles XSS attempt in page parameter" do
      get :test_safe_page_param, params: { page: "<script>alert('XSS')</script>" }
      expect(response.body).to eq("1")
    end

    it "handles SQL injection attempt in page parameter" do
      get :test_safe_page_param, params: { page: "'; DROP TABLE users; --" }
      expect(response.body).to eq("1")
    end

    it "handles valid page numbers" do
      get :test_safe_page_param, params: { page: "2" }
      expect(response.body).to eq("2")
    end

    it "handles missing page parameter" do
      get :test_safe_page_param
      expect(response.body).to eq("1")
    end

    it "handles zero and negative numbers" do
      get :test_safe_page_param, params: { page: "0" }
      expect(response.body).to eq("1")
      
      get :test_safe_page_param, params: { page: "-5" }
      expect(response.body).to eq("1")
    end
  end
end
