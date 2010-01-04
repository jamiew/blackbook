ActionController::Routing::Routes.draw do |map|


  # Forum
  map.resources :forums do |forum|
    forum.resources :forum_threads do |threads|
      threads.resources :forum_posts
    end
  end
  
  map.admin '/admin', :controller => 'admin/base'

  map.resource :user_session # is this 100% necessary? we've explicitly mapped the important routes
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'user_sessions', :action => 'new'
  map.logout '/logout', :controller => 'user_sessions', :action => 'destroy'
  map.forgot_password '/forgot_password',
    :controller => 'password_reset',
    :action => 'new'
  map.resources :password_reset # also not my favorite.

  map.resource :account, :controller => "users" #FIXME DEPRECATEME
  map.resources :users,
        :member => [:change_password],
        # :has_many => [:tags, :comments]
        :has_many => [:comments] do |users|
    users.resources :tags, :as => 'data'
  end

  map.resources :visualizations,
    :as => 'apps', #TODO FIXME
    :has_many => [:comments, :likes]

  map.resources :tags,
    :as => 'data',
    :has_many => [:comments, :likes],
    :collection => [:latest],
    :trailing_slash => true
  map.resources :tags    
  map.vanderlin_tag '/tags/:id/tag.xml', :controller => 'tags', :action => 'show', :format => 'gml'

  # TODO...
  # map.resources :likes    


  map.activity '/activity', :controller => 'home', :action => 'activity'
  
  # # Install the default routes
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
  
  # Home, & lastly serve up static pages when available
  map.root :controller => 'home', :action => 'index'  
  map.connect '/:id.:format', :controller => 'home', :action => 'static'

end
