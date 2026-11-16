class WeatherService
  include ZipCodeNormalizable

  CACHE_TTL = 30.minutes
  RACE_CONDITION_TTL = 10.seconds

  def initialize(zip_code, client: WeatherApiClient.new, cache: Rails.cache)
    @zip_code = normalize_zip_code(zip_code).to_s
    @client = client
    @cache = cache
  end

  def call
    from_cache = true

    payload = @cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: RACE_CONDITION_TTL) do
      from_cache = false
      @client.fetch(@zip_code)
    end

    ForecastResult.success(
      zip_code: @zip_code,
      temperature: payload[:temp],
      high: payload[:high],
      low: payload[:low],
      from_cache: from_cache
    )
  rescue WeatherApiClient::LocationNotFoundError => e
    ForecastResult.failure(zip_code: @zip_code, error_message: e.message, http_status: :unprocessable_content)
  rescue WeatherApiClient::RateLimitError => e
    ForecastResult.failure(zip_code: @zip_code, error_message: e.message, http_status: :too_many_requests)
  rescue WeatherApiClient::TimeoutError => e
    ForecastResult.failure(zip_code: @zip_code, error_message: e.message, http_status: :gateway_timeout)
  rescue WeatherApiClient::MalformedResponseError, WeatherApiClient::UpstreamError => e
    ForecastResult.failure(zip_code: @zip_code, error_message: e.message, http_status: :bad_gateway)
  end

  private

  def cache_key
    "weather:#{@zip_code}"
  end
end
