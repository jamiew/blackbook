Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end


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
  resources :users,
        :member => [:change_password, :latest],
        # :has_many => [:tags, :comments]
        :has_many => [:tags, :visualizations, :comments, :favorites] do |users|
    resources :tags, :as => 'data'
  end
  get '/settings', :controller => 'users', :action => 'edit', as: 'settings'

  # tags => /data
  get '/data' => 'tags#index'
  resources :tags,
    :as => 'data',
    :has_many => [:comments, :favorites],
    :member => {:flipped => :get, :nominate => :post, :thumbnail => [:post,:put], :validate => :get},
    :collection => [:latest, :random]
  resources :tags # /tags vanilla, for backwards-compat (tempt1's eyewriter uses this)

  get '/latest', :controller => 'tags', :action => 'latest', as: 'latest_tag'
  get '/random', :controller => 'tags', :action => 'random', as: 'random_tag'

  get '/validator', :controller => 'tags', :action => 'validate', as: 'validator'
  post  '/validate',  :controller => 'tags', :action => 'validate', as: 'validate'

  # visualizations => /apps
  resources :visualizations,
    :as => 'apps',
    :has_many => [:comments, :favorites],
    :member => {:approve => :put, :unapprove => :put}

  resources :comments

  get '/activity', :controller => 'home', :action => 'activity', as: 'activity'

  # Homepage
  root :controller => 'home', :action => 'index'

  # Lastly serve up static pages when available
  # connect '/:id', :controller => 'home', :action => 'static'

end
