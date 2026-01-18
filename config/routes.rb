Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
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

  # Member attendances
  resources :events, only: [] do
    resource :attendance, only: [ :edit, :update ]
  end

  # Admin namespace
  namespace :admin do
    resources :events do
      resources :attendances, only: [ :index, :create, :update ]
    end

    resources :announcements do
      member do
        post :send_email
      end
    end

    resources :announcement_templates

    resources :venues
  end
end
