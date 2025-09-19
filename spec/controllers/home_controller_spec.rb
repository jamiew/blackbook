# frozen_string_literal: true

require 'rails_helper'

describe HomeController do
  render_views

  before do
    request.env['rack.url_scheme'] = 'https'
    activate_authlogic
  end

  it '/ works' do
    get :index
    expect(response.body).to match(/an open database for Graffiti Markup Language/)
    expect(response).to be_successful
  end

  it '/about works' do
    get :about
    expect(response.body).to match(/About/)
    expect(response).to render_template('home/about')
    expect(response).to be_successful
  end

  describe 'pagination parameter validation' do
    # Test the controller logic without hitting the views
    controller described_class do
      def test_pagination_params
        @page, @per_page = pagination_params
        render plain: @page.to_s
      end
    end

    before do
      routes.draw { get 'test_pagination_params' => 'home#test_pagination_params' }
    end

    it 'handles malicious page parameters safely' do
      get :test_pagination_params, params: { page: "'" }
      expect(response.body).to eq('1')
    end

    it 'handles XSS attempt in page parameter' do
      get :test_pagination_params, params: { page: "<script>alert('XSS')</script>" }
      expect(response.body).to eq('1')
    end

    it 'handles SQL injection attempt in page parameter' do
      get :test_pagination_params, params: { page: "'; DROP TABLE users; --" }
      expect(response.body).to eq('1')
    end

    it 'handles valid page numbers' do
      get :test_pagination_params, params: { page: '2' }
      expect(response.body).to eq('2')
    end

    it 'handles missing page parameter' do
      get :test_pagination_params
      expect(response.body).to eq('1')
    end

    it 'handles zero and negative numbers' do
      get :test_pagination_params, params: { page: '0' }
      expect(response.body).to eq('1')

      get :test_pagination_params, params: { page: '-5' }
      expect(response.body).to eq('1')
    end
  end
end
