class ForecastRequest
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ZipCodeNormalizable

  attribute :zip_code, :string

  validates :zip_code, presence: true

  def zip_code=(value)
    super(normalize_zip_code(value))
  end
end
