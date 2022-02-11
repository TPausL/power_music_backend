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
      namespace :spotify do
        get 'login', to: 'login'
        post 'code', to: 'code'
      end
      namespace :youtube do
        get 'login', to: 'login'
        post 'code', to: 'code'
      end
    end

    get 'test', to: 'merges#test'

    resources :merges
  end
end
