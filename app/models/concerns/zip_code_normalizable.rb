module ZipCodeNormalizable
  extend ActiveSupport::Concern

  private

  def normalize_zip_code(value)
    value.to_s.strip.gsub(/\s+/, " ").upcase.presence
  end
end
