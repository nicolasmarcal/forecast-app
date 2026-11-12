Rails.application.routes.draw do
  root "forecasts#new"
  resource :forecast, only: [ :new, :create ]
  get "up" => "rails/health#show", as: :rails_health_check
end
