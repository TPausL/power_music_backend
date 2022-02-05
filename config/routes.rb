Rails.application.routes.draw do
  defaults format: :json do
    use_doorkeeper do
      skip_controllers :authorizations, :applications, :authorized_applications
    end

    devise_for :users,
               path: 'auth',
               path_names: {
                 sign_in: 'login',
                 sign_out: 'logout',
               },
               controllers: {
                 registrations: 'auth/registrations',
                 #passwords: "auth/password"
               },
               skip: :all

    devise_scope :user do
      post 'auth/register', to: 'auth/registrations#create'
    end

    namespace :auth do
      get 'spotify/login', to: 'spotify#login'
    end

    resources :playlists
  end
end
