module ZipCodeNormalizable
  extend ActiveSupport::Concern

  private

  def normalize_zip_code(value)
    value.to_s.strip.gsub(/[^A-Za-z0-9]/, "").upcase.presence
  end
end
