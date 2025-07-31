Rails.application.routes.draw do
  resources :invoices, only: [:index] do
    collection do
      post :upload_xml
    end
    member do
      post :generate_payment_complement
    end
  end
  resources :payment_complements, only: [] do
    member do
      get :download
    end
  end
end
