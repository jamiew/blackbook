ActionController::Routing::Routes.draw do |map|

  # Requests I'd like to blackhole -- ideally these wouldn't flood my logs either O_o
  #FIXME; what's a better way to handle this idom?
  map.discard_temp_png '/temp.png', :controller => 'home', :action => 'discard'
  map.discard_data_temp_png '/data/temp.png', :controller => 'home', :action => 'discard'
  map.discard_tags_temp_png '/tags/temp.png', :controller => 'home', :action => 'discard'
  
  # Forum (TODO)
  # map.resources :forums do |forum|
  #   forum.resources :forum_threads do |threads|
  #     threads.resources :forum_posts
  #   end
  # end
  
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
        :has_many => [:tags, :visualizations, :comments, :favorites] do |users| 
    users.resources :tags, :as => 'data'
  end
  map.settings '/settings', :controller => 'users', :action => 'edit'

  # intercept bad js/robot GETS to /data/:id/favorites -- TODO should have a 'are you sure you wanna favorite this?' page for GETs
  map.backup_tag_favorites_get '/data/:tag_id/favorites', :method => 'get', :controller => 'favorites', :action => 'create'

  # tags => /data
  map.resources :tags,
    :as => 'data',
    :has_many => [:comments, :favorites],
    :member => [:upload_thumbnail, :flipped],
    :collection => [:latest, :random]
  map.resources :tags # /tags vanilla, for backwards-compat (tempt1's eyewriter uses this)

  # visualizations => /apps
  map.resources :visualizations,
    :as => 'apps',
    :has_many => [:comments, :favorites],
    :member => {:approve => :put, :unapprove => :put}

  # TODO...
  # map.resources :favorites
  map.resources :comments

  map.activity '/activity', :controller => 'home', :action => 'activity'
  
  # # Install the default routes
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
  
  # Home, & lastly serve up static pages when available
  map.root :controller => 'home', :action => 'index'  
  map.connect '/:id.:format', :controller => 'home', :action => 'static'

end
