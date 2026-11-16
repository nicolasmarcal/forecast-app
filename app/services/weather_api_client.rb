require "net/http"
require "json"

class WeatherApiClient
  class Error < StandardError; end
  class TimeoutError < Error; end
  class RateLimitError < Error; end
  class LocationNotFoundError < Error; end
  class MalformedResponseError < Error; end
  class UpstreamError < Error; end

  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 5

  def initialize(api_config: Rails.application.credentials.weather_api, http_adapter: Net::HTTP)
    @api_config = api_config
    @http_adapter = http_adapter
  end

  def fetch(zip_code)
    uri = build_uri(zip_code)
    response = perform_request(uri)

    handle_response(response)
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise TimeoutError, "Weather service timed out. Please try again later."
  rescue SocketError, EOFError, SystemCallError, OpenSSL::SSL::SSLError => e
    raise UpstreamError, "Unable to reach weather service: #{e.message}"
  end

  private

  def build_uri(zip_code)
    uri = URI(@api_config[:base_url])
    uri.query = URI.encode_www_form(
      key: @api_config[:key],
      q: zip_code,
      days: 1
    )
    uri
  end

  def perform_request(uri)
    http = @http_adapter.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    http.request(Net::HTTP::Get.new(uri))
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      parse_payload(response.body)
    when Net::HTTPTooManyRequests
      raise RateLimitError, "Weather API rate limit exceeded. Please try again later."
    when Net::HTTPNotFound, Net::HTTPBadRequest
      raise LocationNotFoundError, "Invalid zip code or location not found."
    else
      raise UpstreamError, "Upstream weather service error (HTTP #{response.code})."
    end
  end

  def parse_payload(body)
    parsed = JSON.parse(body)

    temp = parsed.dig("current", "temp_f")
    high = parsed.dig("forecast", "forecastday", 0, "day", "maxtemp_f")
    low  = parsed.dig("forecast", "forecastday", 0, "day", "mintemp_f")

    if [ temp, high, low ].any?(&:nil?)
      raise MalformedResponseError, "Weather service returned an incomplete payload."
    end

    { temp: temp, high: high, low: low }
  rescue JSON::ParserError
    raise MalformedResponseError, "Weather service returned malformed JSON."
  end
end
