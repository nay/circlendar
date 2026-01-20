Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "signup/sent", to: "registrations#confirmation_sent", as: :confirmation_sent
  get "signup/:token", to: "registrations#new", as: :signup
  post "signup/:token", to: "registrations#create"

  get "confirm", to: "confirmations#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"

  # Dashboard for members
  get "dashboard", to: "dashboard#index"

  # Profile
  resource :profile, only: [ :edit, :update ]

  # Member attendances
  resources :events, only: [] do
    resource :attendance, only: [ :edit, :update ]
  end

  # Admin namespace
  namespace :admin do
    resources :events

    resources :announcements do
      member do
        post :send_email
      end
    end

    resources :announcement_templates

    resources :venues

    resources :members, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]

    resource :setting, only: [ :edit, :update ] do
      post :generate_signup_token, on: :member
    end
  end
end
