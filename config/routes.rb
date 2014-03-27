Rails.application.routes.draw do

  # resources :user_sessions, only: [:new, :create]
  
  get '/d/users/sign_in' => "user_sessions#new", as: "sign_in"
  post '/d/users/sign_in' => "user_sessions#create"
  delete '/d/users/sign_out' => "user_sessions#destroy", as: "sign_out"
  get '/d/users/preferences' => "users#edit", as: "preferences"
  get "/d/users/:id/welcome/:tok" => "users#welcome", as: "welcome"

  resources :users do
    put :confirm, on: :member
  end
  
end
