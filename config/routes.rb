Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :user, only: :show
  resource :consent, only: :create

  root "root#show"

  # Defines the root path route ("/")
  # root "posts#index"
end
