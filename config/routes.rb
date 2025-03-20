Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"
  get "search", to: "home#search", as: :search
  get "up" => "rails/health#show", as: :rails_health_check

  get 'destination/:id', to: 'destination#show', as: :destination

  resources :rides


end
