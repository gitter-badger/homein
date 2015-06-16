Rails.application.routes.draw do
  devise_for :users
  
  resources :places
  root 'places#index'
  
  post 'places/search' => 'places#search', as: 'search_places'
end
