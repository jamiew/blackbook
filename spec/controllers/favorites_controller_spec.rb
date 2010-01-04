require File.dirname(__FILE__) + '/../spec_helper'

describe FavoritesController, "#route_for" do

  it "should map { :controller => 'favorites', :action => 'index' } to /favorites" do
    route_for(:controller => "favorites", :action => "index").should == "/favorites"
  end
  
  it "should map { :controller => 'favorites', :action => 'new' } to /favorites/new" do
    route_for(:controller => "favorites", :action => "new").should == "/favorites/new"
  end
  
  it "should map { :controller => 'favorites', :action => 'show', :id => 1 } to /favorites/1" do
    route_for(:controller => "favorites", :action => "show", :id => 1).should == "/favorites/1"
  end
  
  it "should map { :controller => 'favorites', :action => 'edit', :id => 1 } to /favorites/1/edit" do
    route_for(:controller => "favorites", :action => "edit", :id => 1).should == "/favorites/1/edit"
  end
  
  it "should map { :controller => 'favorites', :action => 'update', :id => 1} to /favorites/1" do
    route_for(:controller => "favorites", :action => "update", :id => 1).should == "/favorites/1"
  end
  
  it "should map { :controller => 'favorites', :action => 'destroy', :id => 1} to /favorites/1" do
    route_for(:controller => "favorites", :action => "destroy", :id => 1).should == "/favorites/1"
  end
  
end

describe FavoritesController, "handling GET /favorites" do

  before do
    @favorite = mock_model(Favorite)
    Favorite.stub!(:find).and_return([@favorite])
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should render index template" do
    do_get
    response.should render_template('index')
  end
  
  it "should find all favorites" do
    Favorite.should_receive(:find).with(:all).and_return([@favorite])
    do_get
  end
  
  it "should assign the found favorites for the view" do
    do_get
    assigns[:favorites].should == [@favorite]
  end
end

describe FavoritesController, "handling GET /favorites.xml" do

  before do
    @favorite = mock_model(Favorite, :to_xml => "XML")
    Favorite.stub!(:find).and_return(@favorite)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find all favorites" do
    Favorite.should_receive(:find).with(:all).and_return([@favorite])
    do_get
  end
  
  it "should render the found favorite as xml" do
    @favorite.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should == "XML"
  end
end

describe FavoritesController, "handling GET /favorites/1" do

  before do
    @favorite = mock_model(Favorite)
    Favorite.stub!(:find).and_return(@favorite)
  end
  
  def do_get
    get :show, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render show template" do
    do_get
    response.should render_template('show')
  end
  
  it "should find the favorite requested" do
    Favorite.should_receive(:find).with("1").and_return(@favorite)
    do_get
  end
  
  it "should assign the found favorite for the view" do
    do_get
    assigns[:favorite].should equal(@favorite)
  end
end

describe FavoritesController, "handling GET /favorites/1.xml" do

  before do
    @favorite = mock_model(Favorite, :to_xml => "XML")
    Favorite.stub!(:find).and_return(@favorite)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the favorite requested" do
    Favorite.should_receive(:find).with("1").and_return(@favorite)
    do_get
  end
  
  it "should render the found favorite as xml" do
    @favorite.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should == "XML"
  end
end

describe FavoritesController, "handling GET /favorites/new" do

  before do
    @favorite = mock_model(Favorite)
    Favorite.stub!(:new).and_return(@favorite)
  end
  
  def do_get
    get :new
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render new template" do
    do_get
    response.should render_template('new')
  end
  
  it "should create an new favorite" do
    Favorite.should_receive(:new).and_return(@favorite)
    do_get
  end
  
  it "should not save the new favorite" do
    @favorite.should_not_receive(:save)
    do_get
  end
  
  it "should assign the new favorite for the view" do
    do_get
    assigns[:favorite].should equal(@favorite)
  end
end

describe FavoritesController, "handling GET /favorites/1/edit" do

  before do
    @favorite = mock_model(Favorite)
    Favorite.stub!(:find).and_return(@favorite)
  end
  
  def do_get
    get :edit, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render edit template" do
    do_get
    response.should render_template('edit')
  end
  
  it "should find the favorite requested" do
    Favorite.should_receive(:find).and_return(@favorite)
    do_get
  end
  
  it "should assign the found favorite for the view" do
    do_get
    assigns[:favorite].should equal(@favorite)
  end
end

describe FavoritesController, "handling POST /favorites" do

  before do
    @favorite = mock_model(Favorite, :to_param => "1")
    Favorite.stub!(:new).and_return(@favorite)
  end
  
  def post_with_successful_save
    @favorite.should_receive(:save).and_return(true)
    post :create, :favorite => {}
  end
  
  def post_with_failed_save
    @favorite.should_receive(:save).and_return(false)
    post :create, :favorite => {}
  end
  
  it "should create a new favorite" do
    Favorite.should_receive(:new).with({}).and_return(@favorite)
    post_with_successful_save
  end

  it "should redirect to the new favorite on successful save" do
    post_with_successful_save
    response.should redirect_to(favorite_url("1"))
  end

  it "should re-render 'new' on failed save" do
    post_with_failed_save
    response.should render_template('new')
  end
end

describe FavoritesController, "handling PUT /favorites/1" do

  before do
    @favorite = mock_model(Favorite, :to_param => "1")
    Favorite.stub!(:find).and_return(@favorite)
  end
  
  def put_with_successful_update
    @favorite.should_receive(:update_attributes).and_return(true)
    put :update, :id => "1"
  end
  
  def put_with_failed_update
    @favorite.should_receive(:update_attributes).and_return(false)
    put :update, :id => "1"
  end
  
  it "should find the favorite requested" do
    Favorite.should_receive(:find).with("1").and_return(@favorite)
    put_with_successful_update
  end

  it "should update the found favorite" do
    put_with_successful_update
    assigns(:favorite).should equal(@favorite)
  end

  it "should assign the found favorite for the view" do
    put_with_successful_update
    assigns(:favorite).should equal(@favorite)
  end

  it "should redirect to the favorite on successful update" do
    put_with_successful_update
    response.should redirect_to(favorite_url("1"))
  end

  it "should re-render 'edit' on failed update" do
    put_with_failed_update
    response.should render_template('edit')
  end
end

describe FavoritesController, "handling DELETE /favorite/1" do

  before do
    request.env["HTTP_REFERER"] = "/favorites"
    @favorite = mock_model(Favorite, :destroy => true)
    Favorite.stub!(:find).and_return(@favorite)
  end
  
  def do_delete
    delete :destroy, :id => "1"
  end

  it "should find the favorite requested" do
    Favorite.should_receive(:find).with("1").and_return(@favorite)
    do_delete
  end
  
  it "should call destroy on the found favorite" do
    @favorite.should_receive(:destroy)
    do_delete
  end
  
  it "should redirect to the favorites list" do
    do_delete
    response.should redirect_to(favorites_url)
  end
end
