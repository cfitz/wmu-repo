MendeleyRepo::Application.routes.draw do
  root :to => "home#index"
  resources :users
  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match '/signout' => 'sessions#destroy', :as => :signout
  match '/signin' => 'sessions#new', :as => :signin
  
end
