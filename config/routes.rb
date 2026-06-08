DroomClient::Engine.routes.draw do

  get '/users/sign_in' => "user_sessions#new", as: "sign_in"
  post '/users/sign_in' => "user_sessions#create"

  delete '/users/sign_out' => "user_sessions#destroy", as: "sign_out"
  get '/users/preferences' => "users#edit", as: "preferences"
  get '/users/suggest' => "users#suggest", as: "suggest_users"
  get '/users/check_email' => "users#check_email", as: "check_email"

  post '/api/users/sign_in' => 'api/sessions#create', as: :api_sign_in
  delete '/api/users/sign_out' => 'api/sessions#destroy', as: :api_sign_out
  post '/users/reset_password' => "passwords#create", as: "reset_password"
  get 'check_authenticate' => 'users#check_authenticate'

  get '/users/remove_profile/:id' => 'users#remove_profile', as: 'remove_profile'
  put '/users/upload_profile_image/:id' => 'users#upload_profile_image', as: 'upload_profile_image'
  put '/users/account_setting_update/:id' => 'users#account_setting_update', as: 'account_setting_update'

  # Dismiss the backup-email reminder banner shown after signing in with a backup email.
  delete '/banners/backup_email' => 'banners#dismiss_backup_email', as: :dismiss_backup_email_banner

  resources :users do
    put :set_password, on: :member
    resources :emails
    resources :addresses
    collection do
      post :sign_up
    end
  end

end
