Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :user, only: %i[show update] do
    post :advance_stage
  end
  resource :consent, only: %i[create show]
  get "progress" => "progress#show"

  resources :conversations, only: %i[create show] do
    post :finish, on: :member
    resources :turns, only: :create, module: :conversations
    resources :voice_turns, only: :create, module: :conversations
    resource :voice_reply, only: :create, module: :conversations
    resource :feedback, only: :show, module: :conversations
    resources :feedback_comments, only: :update, module: :conversations, path: "feedback/comments"
  end

  resources :stage_reviews, only: :show, param: :stage do
    post :acknowledge, on: :member
  end

  resources :stage_quizzes, only: :show, param: :stage do
    post :attempt, on: :member
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
