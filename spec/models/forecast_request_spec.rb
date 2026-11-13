require 'rails_helper'

RSpec.describe ForecastRequest, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:zip_code) }
  end
end
