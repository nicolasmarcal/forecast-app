require "rails_helper"

RSpec.describe ForecastResult do
  describe ".success" do
    subject(:result) do
      described_class.success(
        zip_code: "10001",
        temperature: 72.5,
        high: 78.0,
        low: 65.0,
        from_cache: true
      )
    end

    it "builds a successful result with :ok status" do
      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.http_status).to eq(:ok)
      expect(result.error_message).to be_nil
      expect(result.zip_code).to eq("10001")
      expect(result.temperature).to eq(72.5)
      expect(result.high).to eq(78.0)
      expect(result.low).to eq(65.0)
      expect(result.from_cache).to be(true)
    end

    it "defaults from_cache to false" do
      fresh_result = described_class.success(zip_code: "10001", temperature: 70.0, high: 75.0, low: 60.0)
      expect(fresh_result.from_cache).to be(false)
    end
  end

  describe ".failure" do
    subject(:result) do
      described_class.failure(
        zip_code: "00000",
        error_message: "Invalid zip code or location not found.",
        http_status: :unprocessable_content
      )
    end

    it "builds a failed result with nil weather metrics and semantic status" do
      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.http_status).to eq(:unprocessable_content)
      expect(result.error_message).to eq("Invalid zip code or location not found.")
      expect(result.temperature).to be_nil
      expect(result.high).to be_nil
      expect(result.low).to be_nil
      expect(result.from_cache).to be(false)
    end
  end

  describe "immutability" do
    it "is frozen by Data.define" do
      result = described_class.success(zip_code: "10001", temperature: 70.0, high: 75.0, low: 60.0)
      expect(result).to be_frozen
    end
  end
end
