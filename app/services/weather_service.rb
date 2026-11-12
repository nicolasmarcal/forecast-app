class WeatherService
  def initialize(zipcode)
    @zipcode = zipcode
  end

  def call
    cache_key = "weather-#{@zipcode}"

    is_cached = Rails.cache.exist?(cache_key)

    data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      fetch_from_api
    end

    {
      data: data,
      from_cache: is_cached,
      error: nil
    }
  rescue StandardError => e
    { data: nil, from_cache: false, error: "It wasn't possible to get forecast: #{e.message}" }
  end

  private

  def fetch_from_api
    { temp: 25, high: 28, low: 20 }
  end
end
