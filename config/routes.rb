Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :user, only: %i[show update]
  resource :consent, only: :create

  resources :conversations, only: %i[create show] do
    post :finish, on: :member
    resources :turns, only: :create, module: :conversations
    resource :feedback, only: :show, module: :conversations
    resources :feedback_comments, only: :update, module: :conversations, path: "feedback/comments"
  end

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
