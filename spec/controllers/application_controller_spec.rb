require 'rails_helper'

describe ApplicationController do
  controller do
    def index
      @page = safe_page_param(params[:page])
      render plain: "page: #{@page}"
    end
  end

  describe "#safe_page_param" do
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

    it "supports custom default page" do
      controller.instance_eval do
        def index
          @page = safe_page_param(params[:page], 10)
          render plain: "page: #{@page}"
        end
      end

      get :index
      expect(assigns(:page)).to eq(10)
    end
  end
end