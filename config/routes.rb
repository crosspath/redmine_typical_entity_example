resources :projects do
  resources :clients, only: :index
  resources :products, only: :index
end

resources :clients
resources :products
