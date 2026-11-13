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

        expect(result[:data][:temp]).to be_a(Numeric)
        expect(result[:data][:high]).to be_a(Numeric)
        expect(result[:data][:low]).to be_a(Numeric)
        expect(result[:zip_code]).to eq(zip_code)
        expect(result[:from_cache]).to be_falsey
        expect(result[:error]).to be_nil

        cached_result = service.call
        expect(cached_result[:from_cache]).to be_truthy
      end
    end

    context "when testing failure states (Defensive Architecture)" do
      it "handles network timeouts gracefully" do
        stub_request(:get, api_url).to_timeout

        result = service.call
        expect(result[:error]).to include("It wasn't possible to get forecast: Timeout error.")
      end

      it "handles invalid zip codes (400 Bad Request)" do
        stub_request(:get, api_url).to_return(status: 400)

        result = service.call
        expect(result[:error]).to include("Invalid zip code")
      end
    end

    context "when verifying cache expiration", :vcr do
      it "expires the cache after 30 minutes" do
        freeze_time do
          first_result = service.call
          expect(first_result[:from_cache]).to be_falsey

          immediate_result = service.call
          expect(immediate_result[:from_cache]).to be_truthy
        end

        travel 31.minutes do
          future_result = service.call
          expect(future_result[:from_cache]).to be_falsey
        end
      end
    end
  end
end
