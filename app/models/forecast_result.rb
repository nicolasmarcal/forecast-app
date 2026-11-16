ForecastResult = Data.define(
  :zip_code,
  :temperature,
  :high,
  :low,
  :from_cache,
  :error_message,
  :http_status
) do
  def self.success(zip_code:, temperature:, high:, low:, from_cache: false)
    new(
      zip_code: zip_code,
      temperature: temperature,
      high: high,
      low: low,
      from_cache: from_cache,
      error_message: nil,
      http_status: :ok
    )
  end

  def self.failure(zip_code:, error_message:, http_status:)
    new(
      zip_code: zip_code,
      temperature: nil,
      high: nil,
      low: nil,
      from_cache: false,
      error_message: error_message,
      http_status: http_status
    )
  end

  def success?
    error_message.nil?
  end

  def failure?
    !success?
  end
end
