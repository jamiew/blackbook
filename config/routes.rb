ActionController::Routing::Routes.draw do |map|
  map.resources :likes



  map.root :controller => 'home'
  

  map.admin '/admin', :controller => 'admin/base'

  map.forgot_password '/forgot_password',
  :controller => 'password_reset',
  :action => 'new'

  map.resources :password_reset

  map.resource :user_session
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'user_sessions', :action => 'new'
  map.logout '/logout', :controller => 'user_sessions', :action => 'destroy'

  map.resource :account, :controller => "users"
  
  map.resources :users,
    :has_many => [:tags, :comments]
  
  map.resources :visualizations,
    :has_many => [:comments, :likes] # users? tags?

  map.resources :tags,
    :has_many => [:comments, :likes]  
    

  map.activity '/activity', :controller => 'home', :action => 'activity'

  
  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
