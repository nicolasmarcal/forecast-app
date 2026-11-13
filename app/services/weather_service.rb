require "net/http"
require "json"

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
    api_config = Rails.application.credentials.weather_api

    uri = URI(api_config[:base_url])
    uri.query = URI.encode_www_form({
                                      key: api_config[:key],
                                      q: @zipcode,
                                      days: 1
                                    })
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    http.open_timeout = 3
    http.read_timeout = 5

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      parsed_response = JSON.parse(response.body)

      {
        temp: parsed_response.dig("current", "temp_c"),
        high: parsed_response.dig("forecast", "forecastday", 0, "day", "maxtemp_f"),
        low: parsed_response.dig("forecast", "forecastday", 0, "day", "mintemp_f")
      }
    when Net::HTTPTooManyRequests
      raise "API rate limit exceeded. Please try again later."
    when Net::HTTPNotFound, Net::HTTPBadRequest
      raise "Invalid zip code or location not found."
    else
      raise "Error calling API: #{response.code}."
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise "Timeout error."
  rescue SocketError, EOFError, SystemCallError => e
    raise "Error calling API: #{e.message}"
  end
end
