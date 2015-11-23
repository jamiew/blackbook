Rails.application.routes.draw do

  # Requests to blackhole -- ideally these wouldn't flood my logs either O_o
  # TODO handle inside nginx instead
  get '/temp.png', :controller => 'home', :action => 'discard', as: 'discard_temp_png'
  get '/data/temp.png', :controller => 'home', :action => 'discard', as: 'discard_data_temp_png'
  get '/tags/temp.png', :controller => 'home', :action => 'discard', as: 'discard_tags_temp_png'

  get '/signup', :controller => 'users', :action => 'new', as: 'signup'
  resource :user_session # For create/destroy associated with login/logout
  get '/login', :controller => 'user_sessions', :action => 'new', as: 'login'
  get '/logout', :controller => 'user_sessions', :action => 'destroy', as: 'logout'
  get '/forgot_password', :controller => 'password_reset', :action => 'new', as: 'forgot_password'
  resources :password_reset # also not my favorite.

  resource :account, :controller => "users" #FIXME DEPRECATEME
  resources :users, member: [:change_password, :latest] do
    resources :tags, :as => 'data'
    # resources :visualizations
    resources :comments
    resources :favorites
  end
  get '/settings', :controller => 'users', :action => 'edit', as: 'settings'

  # tags => /data
  resources :tags,
    :path => 'data',
    :member => {:flipped => :get, :nominate => :post, :thumbnail => [:post,:put], :validate => :get},
    :collection => [:latest, :random] do
      resources :comments
      resources :favorites
  end

  resources :tags # /tags vanilla, for backwards-compat (tempt1's eyewriter uses this)

  get '/latest', :controller => 'tags', :action => 'latest', as: 'latest_tag'
  get '/random', :controller => 'tags', :action => 'random', as: 'random_tag'

  get '/validator', :controller => 'tags', :action => 'validate', as: 'validator'
  post  '/validate',  :controller => 'tags', :action => 'validate', as: 'validate'
  post  '/validate',  :controller => 'tags', :action => 'validate', as: 'validate_tag'
  # ^ FIXME what is validate vs. validate_path? both seemed to be used...

  # visualizations => /apps
  resources :visualizations,
    :path => 'apps',
    :member => {:approve => :put, :unapprove => :put} do
    resources :comments
    resources :favorites
  end

  resources :comments

  get '/activity', :controller => 'home', :action => 'activity', as: 'activity'

  # Homepage
  root :controller => 'home', :action => 'index'

  # Lastly serve up static pages when available
  # connect '/:id', :controller => 'home', :action => 'static'

end
