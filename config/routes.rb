Rails.application.routes.draw do

  # Old/bad URLs to send to /dev/null
  # TODO handle inside nginx or similar instead! Yeesh
  get '/temp.png', controller: 'home', action: 'discard', as: 'discard_temp_png'
  get '/data/temp.png', controller: 'home', action: 'discard', as: 'discard_data_temp_png'
  get '/tags/temp.png', controller: 'home', action: 'discard', as: 'discard_tags_temp_png'

  # Users/authentication via authlogic
  resource  :user_session
  resources :password_reset
  get '/signup', controller: 'users', action: 'new', as: 'signup'
  get '/login', controller: 'user_sessions', action: 'new', as: 'login'
  get '/logout', controller: 'user_sessions', action: 'destroy', as: 'logout'
  get '/forgot_password', controller: 'password_reset', action: 'new', as: 'forgot_password'

  resources :users, only: [:show, :create] do
    resources :tags
  end
  get '/settings', controller: 'users', action: 'edit', as: 'settings'
  get '/account/change_password' => 'users#change_password', as: 'change_password_user'
  resource :account, controller: "users" # FIXME needed for password resets...

  # Tags/data
  resources :tags, path: 'data' do
    resources :favorites, only: [:create, :destroy]

    collection do
      get :latest
      get :random
    end

    member do
      get :flipped
      post :nominate
      post :thumbnail
      put :thumbnail
      get :validate
    end
  end

  # TODO can these be inside the :tags resource declaration but maintain the /shorturls?
  get '/latest', controller: 'tags', action: 'latest', as: 'latest_tag'
  get '/random', controller: 'tags', action: 'random', as: 'random_tag'

  get  '/validator' => 'tags#validate', as: 'validator'
  post '/validate' => 'tags#validate', as: 'validate'

  # Apps
  resources :visualizations, path: 'apps' do
    member do
      put :approve
      put :unapprove
    end
  end

  # Everything else
  # FIXME restrict this some more too
  resources :favorites

  get '/activity' => 'home#activity', as: 'activity'

  get '/about' => 'home#about', as: 'about'

  root controller: 'home', action: 'index'
end
