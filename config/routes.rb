Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :user, only: :show
  resource :consent, only: :create

  namespace :placement do
    resource :attempt, only: %i[create show] do
      post :start
      post :play
      post :retake
    end
    resources :responses, only: :create
    resource :writing, only: :create
    resource :recording, only: :create
  end

  root "root#show"

  # Defines the root path route ("/")
  # root "posts#index"
end
