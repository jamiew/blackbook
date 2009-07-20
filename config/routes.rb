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
#== Route Map
# Generated on 20 Jul 2009 01:26
#
#                      likes GET    /likes(.:format)                                              {:controller=>"likes", :action=>"index"}
#                            POST   /likes(.:format)                                              {:controller=>"likes", :action=>"create"}
#                   new_like GET    /likes/new(.:format)                                          {:controller=>"likes", :action=>"new"}
#                  edit_like GET    /likes/:id/edit(.:format)                                     {:controller=>"likes", :action=>"edit"}
#                       like GET    /likes/:id(.:format)                                          {:controller=>"likes", :action=>"show"}
#                            PUT    /likes/:id(.:format)                                          {:controller=>"likes", :action=>"update"}
#                            DELETE /likes/:id(.:format)                                          {:controller=>"likes", :action=>"destroy"}
#                       root        /                                                             {:controller=>"home", :action=>"index"}
#                      admin        /admin                                                        {:controller=>"admin/base", :action=>"index"}
#            forgot_password        /forgot_password                                              {:controller=>"password_reset", :action=>"new"}
#       password_reset_index GET    /password_reset(.:format)                                     {:controller=>"password_reset", :action=>"index"}
#                            POST   /password_reset(.:format)                                     {:controller=>"password_reset", :action=>"create"}
#         new_password_reset GET    /password_reset/new(.:format)                                 {:controller=>"password_reset", :action=>"new"}
#        edit_password_reset GET    /password_reset/:id/edit(.:format)                            {:controller=>"password_reset", :action=>"edit"}
#             password_reset GET    /password_reset/:id(.:format)                                 {:controller=>"password_reset", :action=>"show"}
#                            PUT    /password_reset/:id(.:format)                                 {:controller=>"password_reset", :action=>"update"}
#                            DELETE /password_reset/:id(.:format)                                 {:controller=>"password_reset", :action=>"destroy"}
#           new_user_session GET    /user_session/new(.:format)                                   {:controller=>"user_sessions", :action=>"new"}
#          edit_user_session GET    /user_session/edit(.:format)                                  {:controller=>"user_sessions", :action=>"edit"}
#               user_session GET    /user_session(.:format)                                       {:controller=>"user_sessions", :action=>"show"}
#                            PUT    /user_session(.:format)                                       {:controller=>"user_sessions", :action=>"update"}
#                            DELETE /user_session(.:format)                                       {:controller=>"user_sessions", :action=>"destroy"}
#                            POST   /user_session(.:format)                                       {:controller=>"user_sessions", :action=>"create"}
#                     signup        /signup                                                       {:controller=>"users", :action=>"new"}
#                      login        /login                                                        {:controller=>"user_sessions", :action=>"new"}
#                     logout        /logout                                                       {:controller=>"user_sessions", :action=>"destroy"}
#                new_account GET    /account/new(.:format)                                        {:controller=>"users", :action=>"new"}
#               edit_account GET    /account/edit(.:format)                                       {:controller=>"users", :action=>"edit"}
#                    account GET    /account(.:format)                                            {:controller=>"users", :action=>"show"}
#                            PUT    /account(.:format)                                            {:controller=>"users", :action=>"update"}
#                            DELETE /account(.:format)                                            {:controller=>"users", :action=>"destroy"}
#                            POST   /account(.:format)                                            {:controller=>"users", :action=>"create"}
#                      users GET    /users(.:format)                                              {:controller=>"users", :action=>"index"}
#                            POST   /users(.:format)                                              {:controller=>"users", :action=>"create"}
#                   new_user GET    /users/new(.:format)                                          {:controller=>"users", :action=>"new"}
#                  edit_user GET    /users/:id/edit(.:format)                                     {:controller=>"users", :action=>"edit"}
#                       user GET    /users/:id(.:format)                                          {:controller=>"users", :action=>"show"}
#                            PUT    /users/:id(.:format)                                          {:controller=>"users", :action=>"update"}
#                            DELETE /users/:id(.:format)                                          {:controller=>"users", :action=>"destroy"}
#                  user_tags GET    /users/:user_id/tags(.:format)                                {:controller=>"tags", :action=>"index"}
#                            POST   /users/:user_id/tags(.:format)                                {:controller=>"tags", :action=>"create"}
#               new_user_tag GET    /users/:user_id/tags/new(.:format)                            {:controller=>"tags", :action=>"new"}
#              edit_user_tag GET    /users/:user_id/tags/:id/edit(.:format)                       {:controller=>"tags", :action=>"edit"}
#                   user_tag GET    /users/:user_id/tags/:id(.:format)                            {:controller=>"tags", :action=>"show"}
#                            PUT    /users/:user_id/tags/:id(.:format)                            {:controller=>"tags", :action=>"update"}
#                            DELETE /users/:user_id/tags/:id(.:format)                            {:controller=>"tags", :action=>"destroy"}
#              user_comments GET    /users/:user_id/comments(.:format)                            {:controller=>"comments", :action=>"index"}
#                            POST   /users/:user_id/comments(.:format)                            {:controller=>"comments", :action=>"create"}
#           new_user_comment GET    /users/:user_id/comments/new(.:format)                        {:controller=>"comments", :action=>"new"}
#          edit_user_comment GET    /users/:user_id/comments/:id/edit(.:format)                   {:controller=>"comments", :action=>"edit"}
#               user_comment GET    /users/:user_id/comments/:id(.:format)                        {:controller=>"comments", :action=>"show"}
#                            PUT    /users/:user_id/comments/:id(.:format)                        {:controller=>"comments", :action=>"update"}
#                            DELETE /users/:user_id/comments/:id(.:format)                        {:controller=>"comments", :action=>"destroy"}
#             visualizations GET    /visualizations(.:format)                                     {:controller=>"visualizations", :action=>"index"}
#                            POST   /visualizations(.:format)                                     {:controller=>"visualizations", :action=>"create"}
#          new_visualization GET    /visualizations/new(.:format)                                 {:controller=>"visualizations", :action=>"new"}
#         edit_visualization GET    /visualizations/:id/edit(.:format)                            {:controller=>"visualizations", :action=>"edit"}
#              visualization GET    /visualizations/:id(.:format)                                 {:controller=>"visualizations", :action=>"show"}
#                            PUT    /visualizations/:id(.:format)                                 {:controller=>"visualizations", :action=>"update"}
#                            DELETE /visualizations/:id(.:format)                                 {:controller=>"visualizations", :action=>"destroy"}
#     visualization_comments GET    /visualizations/:visualization_id/comments(.:format)          {:controller=>"comments", :action=>"index"}
#                            POST   /visualizations/:visualization_id/comments(.:format)          {:controller=>"comments", :action=>"create"}
#  new_visualization_comment GET    /visualizations/:visualization_id/comments/new(.:format)      {:controller=>"comments", :action=>"new"}
# edit_visualization_comment GET    /visualizations/:visualization_id/comments/:id/edit(.:format) {:controller=>"comments", :action=>"edit"}
#      visualization_comment GET    /visualizations/:visualization_id/comments/:id(.:format)      {:controller=>"comments", :action=>"show"}
#                            PUT    /visualizations/:visualization_id/comments/:id(.:format)      {:controller=>"comments", :action=>"update"}
#                            DELETE /visualizations/:visualization_id/comments/:id(.:format)      {:controller=>"comments", :action=>"destroy"}
#        visualization_likes GET    /visualizations/:visualization_id/likes(.:format)             {:controller=>"likes", :action=>"index"}
#                            POST   /visualizations/:visualization_id/likes(.:format)             {:controller=>"likes", :action=>"create"}
#     new_visualization_like GET    /visualizations/:visualization_id/likes/new(.:format)         {:controller=>"likes", :action=>"new"}
#    edit_visualization_like GET    /visualizations/:visualization_id/likes/:id/edit(.:format)    {:controller=>"likes", :action=>"edit"}
#         visualization_like GET    /visualizations/:visualization_id/likes/:id(.:format)         {:controller=>"likes", :action=>"show"}
#                            PUT    /visualizations/:visualization_id/likes/:id(.:format)         {:controller=>"likes", :action=>"update"}
#                            DELETE /visualizations/:visualization_id/likes/:id(.:format)         {:controller=>"likes", :action=>"destroy"}
#                       tags GET    /tags(.:format)                                               {:controller=>"tags", :action=>"index"}
#                            POST   /tags(.:format)                                               {:controller=>"tags", :action=>"create"}
#                    new_tag GET    /tags/new(.:format)                                           {:controller=>"tags", :action=>"new"}
#                   edit_tag GET    /tags/:id/edit(.:format)                                      {:controller=>"tags", :action=>"edit"}
#                        tag GET    /tags/:id(.:format)                                           {:controller=>"tags", :action=>"show"}
#                            PUT    /tags/:id(.:format)                                           {:controller=>"tags", :action=>"update"}
#                            DELETE /tags/:id(.:format)                                           {:controller=>"tags", :action=>"destroy"}
#               tag_comments GET    /tags/:tag_id/comments(.:format)                              {:controller=>"comments", :action=>"index"}
#                            POST   /tags/:tag_id/comments(.:format)                              {:controller=>"comments", :action=>"create"}
#            new_tag_comment GET    /tags/:tag_id/comments/new(.:format)                          {:controller=>"comments", :action=>"new"}
#           edit_tag_comment GET    /tags/:tag_id/comments/:id/edit(.:format)                     {:controller=>"comments", :action=>"edit"}
#                tag_comment GET    /tags/:tag_id/comments/:id(.:format)                          {:controller=>"comments", :action=>"show"}
#                            PUT    /tags/:tag_id/comments/:id(.:format)                          {:controller=>"comments", :action=>"update"}
#                            DELETE /tags/:tag_id/comments/:id(.:format)                          {:controller=>"comments", :action=>"destroy"}
#                  tag_likes GET    /tags/:tag_id/likes(.:format)                                 {:controller=>"likes", :action=>"index"}
#                            POST   /tags/:tag_id/likes(.:format)                                 {:controller=>"likes", :action=>"create"}
#               new_tag_like GET    /tags/:tag_id/likes/new(.:format)                             {:controller=>"likes", :action=>"new"}
#              edit_tag_like GET    /tags/:tag_id/likes/:id/edit(.:format)                        {:controller=>"likes", :action=>"edit"}
#                   tag_like GET    /tags/:tag_id/likes/:id(.:format)                             {:controller=>"likes", :action=>"show"}
#                            PUT    /tags/:tag_id/likes/:id(.:format)                             {:controller=>"likes", :action=>"update"}
#                            DELETE /tags/:tag_id/likes/:id(.:format)                             {:controller=>"likes", :action=>"destroy"}
#                   activity        /activity                                                     {:controller=>"home", :action=>"activity"}
#                                   /:controller/:action/:id                                      
#                                   /:controller/:action/:id(.:format)                            
