Rails.application.routes.draw do
  root "documents#index"

  resources :documents, only: %i[index new create show] do
    member do
      # Starts signing and redirects to the DocuSign signing session
      post :sign
      # Where DocuSign returns the signer (the envelope's return_url)
      get :signed
      # Signed PDF download
      get :download
    end
  end

  # Stand-in for the DocuSign signing screen, mounted only in mock mode.
  # ENV is read directly here: constants are not autoloadable while routes are drawn.
  if ENV["DOCUSIGN_MOCK"] == "true" || Rails.env.test?
    get  "mock_docusign/:envelope_id", to: "mock_docusign#show", as: :mock_docusign
    post "mock_docusign/:envelope_id", to: "mock_docusign#complete", as: :complete_mock_docusign
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
