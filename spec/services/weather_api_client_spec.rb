require "rails_helper"

RSpec.describe WeatherApiClient do
  subject(:client) { described_class.new(api_config: { base_url: "https://api.weatherapi.com/v1/forecast.json",
                                                       key: "test-key" }) }

  let(:api_url) { /api.weatherapi.com/ }

  describe "#fetch" do
    it "parses current and forecast temperatures on 200 OK" do
      body = {
        current: { temp_f: 68.4 },
        forecast: { forecastday: [ { day: { maxtemp_f: 74.1, mintemp_f: 59.2 } } ] }
      }.to_json

      stub_request(:get, api_url).to_return(status: 200, body: body)

      expect(client.fetch("10001")).to eq({ temp: 68.4, high: 74.1, low: 59.2 })
    end

    it "raises UpstreamError on 500 Internal Server Error" do
      stub_request(:get, api_url).to_return(status: 500)

      expect { client.fetch("10001") }.to raise_error(WeatherApiClient::UpstreamError, /HTTP 500/)
    end

    it "raises UpstreamError on network socket failures" do
      stub_request(:get, api_url).to_raise(SocketError.new("Failed to open TCP connection"))

      expect { client.fetch("10001") }.to raise_error(WeatherApiClient::UpstreamError, /Unable to reach/)
    end
  end
end
