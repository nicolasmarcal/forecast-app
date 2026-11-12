class ForecastRequest
  include ActiveModel::Model

  attr_accessor :zip_code

  validates :zip_code, presence: true
end
