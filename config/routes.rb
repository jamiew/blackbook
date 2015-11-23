Rails.application.routes.draw do

  # Requests to blackhole -- ideally these wouldn't flood my logs either O_o
  # TODO handle inside nginx instead
  get '/temp.png', :controller => 'home', :action => 'discard', as: 'discard_temp_png'
  get '/data/temp.png', :controller => 'home', :action => 'discard', as: 'discard_data_temp_png'
  get '/tags/temp.png', :controller => 'home', :action => 'discard', as: 'discard_tags_temp_png'

  # Users/authentication
  get '/signup', :controller => 'users', :action => 'new', as: 'signup'
  resource :user_session # For create/destroy associated with login/logout
  get '/login', :controller => 'user_sessions', :action => 'new', as: 'login'
  get '/logout', :controller => 'user_sessions', :action => 'destroy', as: 'logout'
  get '/forgot_password', :controller => 'password_reset', :action => 'new', as: 'forgot_password'
  resources :password_reset # also not my favorite.

  resource :account, :controller => "users" # FIXME DEPRECATEME
  # ^^^ what is this?

  resources :users do
    # resources :tags, :as => 'data'
    # resources :comments
    # resources :favorites

    get :change_password, on: :member
    get :latest, on: :member
  end
  get '/settings', :controller => 'users', :action => 'edit', as: 'settings'

  # tags => /data
  resources :tags, path: 'data' do
    resources :comments
    resources :favorites

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

  # resources :tags # /tags vanilla, for backwards-compat (tempt1's eyewriter uses this)

  get '/latest', :controller => 'tags', :action => 'latest', as: 'latest_tag'
  get '/random', :controller => 'tags', :action => 'random', as: 'random_tag'

  get '/validator' => 'tags#validate', as: 'validator'
  post  '/validate' => 'tags#validate', as: 'validate'

  resources :visualizations, path: 'apps' do
    resources :comments
    resources :favorites

    member do
      put :approve
      put :unapprove
    end
  end

  resources :favorites

  resources :comments

  get '/activity' => 'home#activity', as: 'activity'

  root :controller => 'home', :action => 'index'

  # Lastly serve up static pages when available
  get '/:id' => 'home#static'
end
