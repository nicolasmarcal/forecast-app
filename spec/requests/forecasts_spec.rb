require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
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
end
