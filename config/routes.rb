ActionController::Routing::Routes.draw do |map|

  # Requests I'd like to blackhole -- ideally these wouldn't flood my logs either O_o
  map.discard_tag_temp_png '/tags/temp.:format', :controller => 'home', :action => 'discard'
  

  # Forum -- REMOVEME
  map.resources :forums do |forum|
    forum.resources :forum_threads do |threads|
      threads.resources :forum_posts
    end
  end
  
  map.admin '/admin', :controller => 'admin/base'

  map.signup '/signup', :controller => 'users', :action => 'new'
  map.resource :user_session # For create/destroy associated with login/logout
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
        :has_many => [:visualizations, :comments, :favorites] do |users| #FIXME remove visualizations nested association -- not being used
    users.resources :tags, :as => 'data'
  end

  map.resources :visualizations,
    :as => 'apps', #TODO FIXME
    :has_many => [:comments, :favorites],
    :member => {:approve => :put, :unapprove => :put}

  map.resources :tags,
    :as => 'data',
    :has_many => [:comments, :favorites],
    :collection => [:latest],
    :trailing_slash => true
  map.resources :tags    
  map.vanderlin_tag '/tags/:id/tag.xml', :controller => 'tags', :action => 'show', :format => 'gml'

  # TODO...
  map.resources :favorites
  map.resources :comments


  map.activity '/activity', :controller => 'home', :action => 'activity'
  
  # # Install the default routes
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
  
  # Home, & lastly serve up static pages when available
  map.root :controller => 'home', :action => 'index'  
  map.connect '/:id.:format', :controller => 'home', :action => 'static'

end
