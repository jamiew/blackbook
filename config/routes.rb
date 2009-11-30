ActionController::Routing::Routes.draw do |map|


  map.resources :forums





  # map.root :controller => 'home'
  map.root :controller => 'tags', :action => 'index'
  
  map.admin '/admin', :controller => 'admin/base'

  map.forgot_password '/forgot_password',
  :controller => 'password_reset',
  :action => 'new'

  map.resources :password_reset

  map.resource :user_session
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'user_sessions', :action => 'new'
  map.logout '/logout', :controller => 'user_sessions', :action => 'destroy'

  map.resource :account, :controller => "users" #DEPRECATEME
  map.resources :users,
    :member => [:change_password],
    :has_many => [:tags, :comments]

  # TODO
  # map.resources :apps
  map.resources :visualizations,
    :as => 'apps', #TODO DEPRECATEME
    :has_many => [:comments, :likes]

  map.resources :tags,
    :as => 'data', #TODO DEPRECATEME
    :has_many => [:comments, :likes],
    :collection => [:latest],
    :trailing_slash => true
  map.vanderlin_tag '/tags/:id/tag.xml', :controller => 'tags', :action => 'show', :format => 'gml'

  map.resources :likes    

  map.activity '/activity', :controller => 'home', :action => 'activity'

  ## Lastly, flat-style /jamiew URLs -- TODO!
  # map.user '/:id', :controller => 'users', :action => 'show'
  
  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
