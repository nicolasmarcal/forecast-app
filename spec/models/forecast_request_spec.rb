require 'rails_helper'

RSpec.describe ForecastRequest, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:zip_code) }

    it "rejects strings containing only whitespace" do
      request = described_class.new(zip_code: "   ")
      expect(request).not_to be_valid
    end
  end

  describe "normalization" do
    it "strips leading/trailing whitespace, collapses internal spaces, and upcases" do
      request = described_class.new(zip_code: "  sw1a   1aa  ")
      expect(request.zip_code).to eq("SW1A 1AA")
    end
  end
end
