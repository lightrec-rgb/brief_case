Rails.application.routes.draw do
  # Devise
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
    authenticated :user do
  root "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root "pages#home"
  end

  # subjects live at /decks
  resources :subjects, path: "decks"

  # cases live at /entries
  resources :card_templates,
            path: "entries",
            as:   :entries,
            only: [ :index, :new, :create, :show, :edit, :update, :destroy ]


  # study sessions
  resources :sessions, path: "learn", controller: "sessions", only: [ :index, :new, :create, :show, :destroy ] do
  member do
    post :start, :pause, :resume, :reset, :advance
  end
end

  # session items
  resources :session_items, only: [] do
    member do
      post :seen
      post :done
    end
  end

  # Acts and provisions
  resources :acts, only: [:index, :new, :create, :show, :edit, :update] do
    # Provisions are created under an Act
    resources :statutes, only: [:new, :create, :edit, :update]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "dashboard/index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
