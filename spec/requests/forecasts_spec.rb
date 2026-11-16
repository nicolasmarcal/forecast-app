require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  before { Rails.cache.clear }
  describe "POST /forecast" do
    context "with valid parameters", :vcr do
      it "returns a successful turbo stream response" do
        post forecast_path, params: { forecast_request: { zip_code: "10001" } }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("10001")
      end
    end

    context "with invalid parameters" do
      it "renders unprocessable entity (422)" do
        post forecast_path, params: { forecast_request: { zip_code: "" } }, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "JSON API (POST /forecast)" do
    let(:api_headers) { { "Accept" => "application/json", "User-Agent" => "curl/8.1.2" } }

    context "POST /forecast with valid JSON body", :vcr do
      it "returns 200 OK with the complete forecast JSON payload" do
        post forecast_path,
             params: { zip_code: "10001" }.to_json,
             headers: api_headers.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/json")

        json = response.parsed_body
        expect(json).to include(
                          "zip_code" => "10001",
                          "temperature" => a_kind_of(Numeric),
                          "high" => a_kind_of(Numeric),
                          "low" => a_kind_of(Numeric),
                          "from_cache" => false
                        )
      end
    end

    context "with invalid parameters" do
      it "returns 422 Unprocessable Content with validation errors" do
        post forecast_path, params: { zip_code: "" }, headers: api_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to be_present
      end
    end
  end

  describe "JSON API (POST /forecast)" do
    context "GET /" do
      it "renders the search form" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/html")
      end
    end

    context "POST /forecast with valid parameters", :vcr do
      it "renders HTML response with forecast data" do
        post forecast_path, params: { forecast_request: { zip_code: "10001" } }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/html")
      end
    end

    context "POST /forecast with invalid parameters" do
      it "renders unprocessable content (422) in HTML" do
        post forecast_path, params: { forecast_request: { zip_code: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq("text/html")
      end
    end
  end
end
