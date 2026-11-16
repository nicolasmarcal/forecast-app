require 'rails_helper'
include ActiveSupport::Testing::TimeHelpers

RSpec.describe WeatherService do
  let(:zip_code) { "10001" }
  let(:service) { described_class.new(zip_code) }
  let(:api_url) { /api.weatherapi.com/ }

  before { Rails.cache.clear }

  describe "#call" do
    context "when the API returns a successful response", :vcr do
      it "fetches data from the API and caches the result" do
        result = service.call

        expect(result).to be_success
        expect(result.http_status).to eq(:ok)
        expect(result.temperature).to be_a(Numeric)
        expect(result.high).to be_a(Numeric)
        expect(result.low).to be_a(Numeric)
        expect(result.zip_code).to eq(zip_code)
        expect(result.from_cache).to be(false)
        expect(result.error_message).to be_nil

        cached_result = service.call
        expect(cached_result.from_cache).to be(true)
      end
    end

    context "when testing dependency injection" do
      it "uses the injected client without making external HTTP calls" do
        fake_client = instance_double(WeatherApiClient, fetch: { temp: 72.5, high: 78.0, low: 65.0 })
        injected_service = described_class.new("10001", client: fake_client)

        result = injected_service.call

        expect(result).to be_success
        expect(result.temperature).to eq(72.5)
        expect(fake_client).to have_received(:fetch).with("10001")
      end
    end

    context "when testing failure states and semantic HTTP status mapping" do
      it "maps network timeouts to :gateway_timeout (504)" do
        stub_request(:get, api_url).to_timeout

        result = service.call
        expect(result).to be_failure
        expect(result.http_status).to eq(:gateway_timeout)
        expect(result.error_message).to eq("Weather service timed out. Please try again later.")
      end

      it "maps invalid zip codes (400/404) to :unprocessable_content (422)" do
        stub_request(:get, api_url).to_return(status: 400)

        result = service.call
        expect(result).to be_failure
        expect(result.http_status).to eq(:unprocessable_content)
        expect(result.error_message).to include("Invalid zip code")
      end

      it "maps rate limit responses (429) to :too_many_requests (429)" do
        stub_request(:get, api_url).to_return(status: 429)

        result = service.call
        expect(result).to be_failure
        expect(result.http_status).to eq(:too_many_requests)
        expect(result.error_message).to include("rate limit")
      end

      it "maps malformed JSON responses to :bad_gateway (502)" do
        stub_request(:get, api_url).to_return(status: 200, body: "not-valid-json{{{")

        result = service.call
        expect(result).to be_failure
        expect(result.http_status).to eq(:bad_gateway)
        expect(result.error_message).to include("malformed JSON")
      end

      it "maps incomplete JSON payloads to :bad_gateway (502)" do
        stub_request(:get, api_url).to_return(status: 200, body: { current: {} }.to_json)

        result = service.call
        expect(result).to be_failure
        expect(result.http_status).to eq(:bad_gateway)
        expect(result.error_message).to include("incomplete payload")
      end

      it "does not swallow unexpected programming errors" do
        broken_client = instance_double(WeatherApiClient)
        allow(broken_client).to receive(:fetch).and_raise(NoMethodError, "undefined method 'foo'")

        expect { described_class.new("10001", client: broken_client).call }.to raise_error(NoMethodError)
      end
    end

    context "when verifying cache expiration", :vcr do
      it "expires the cache after 30 minutes" do
        freeze_time do
          first_result = service.call
          expect(first_result.from_cache).to be(false)

          immediate_result = service.call
          expect(immediate_result.from_cache).to be(true)
        end

        travel 31.minutes do
          future_result = service.call
          expect(future_result.from_cache).to be(false)
        end
      end
    end

    context "when handling cache normalization and concurrency", :vcr do
      it "normalizes equivalent inputs to hit the same cache key" do
        first_result = described_class.new("90001").call
        expect(first_result.from_cache).to be(false)

        second_result = described_class.new("  9.0 001  ").call
        expect(second_result.from_cache).to be(true)
        expect(second_result.zip_code).to eq("90001")
      end

      it "configures race_condition_ttl to prevent cache stampedes" do
        allow(Rails.cache).to receive(:fetch).and_call_original

        service.call

        expect(Rails.cache).to have_received(:fetch).with(
          "weather:10001",
          expires_in: 30.minutes,
          race_condition_ttl: 10.seconds
        )
      end
    end
  end
end
