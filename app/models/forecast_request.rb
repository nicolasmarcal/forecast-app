class ForecastRequest
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ZipCodeNormalizable

  attribute :zip_code, :string

  validates :zip_code, presence: true

  def initialize(attributes = {})
    super
    self.zip_code = normalize_zip_code(zip_code)
  end
end
