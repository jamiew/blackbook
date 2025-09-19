require 'rails_helper'

describe ApplicationController do
  controller do
    def index
      @page, @per_page = pagination_params
      render plain: "page: #{@page}, per_page: #{@per_page}"
    end
  end

  describe "#pagination_params" do
    it "returns 1 for malicious strings" do
      get :index, params: { page: "'" }
      expect(assigns(:page)).to eq(1)
    end

    it "returns 1 for XSS attempts" do
      get :index, params: { page: "<script>alert('XSS')</script>" }
      expect(assigns(:page)).to eq(1)
    end

    it "returns 1 for SQL injection attempts" do
      get :index, params: { page: "'; DROP TABLE users; --" }
      expect(assigns(:page)).to eq(1)
    end

    it "returns 1 for zero or negative numbers" do
      get :index, params: { page: "0" }
      expect(assigns(:page)).to eq(1)

      get :index, params: { page: "-5" }
      expect(assigns(:page)).to eq(1)
    end

    it "returns valid positive integers" do
      get :index, params: { page: "5" }
      expect(assigns(:page)).to eq(5)
    end

    it "returns 1 when no page parameter is provided" do
      get :index
      expect(assigns(:page)).to eq(1)
    end

    it "supports custom per_page values" do
      controller.instance_eval do
        def index
          @page, @per_page = pagination_params(per_page: 50)
          render plain: "page: #{@page}, per_page: #{@per_page}"
        end
      end

      get :index
      expect(assigns(:per_page)).to eq(50)
    end

    it "validates per_page parameter" do
      get :index
      expect(assigns(:per_page)).to eq(20)  # default
    end

    it "accepts valid per_page from params" do
      get :index, params: { per_page: "10" }
      expect(assigns(:per_page)).to eq(10)
    end

    it "enforces max_per_page limit" do
      get :index, params: { per_page: "1000" }
      expect(assigns(:per_page)).to eq(100)  # capped at max_per_page
    end

    it "handles malicious per_page values" do
      get :index, params: { per_page: "'; DROP TABLE users; --" }
      expect(assigns(:per_page)).to eq(20)  # falls back to default
    end
  end
end