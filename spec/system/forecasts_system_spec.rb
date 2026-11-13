require 'rails_helper'

RSpec.describe "Forecasts System", type: :system do
  before do
    Rails.cache.clear
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
    end
  end

  it "allows a user to search for a weather forecast", :vcr do
    visit root_path

    fill_in "Type your zip code here", with: "10001"
    click_on "Search"

    expect(page).to have_text("10001")
    expect(page).to have_text("Result for: 10001")
  end

  it "informs that the information is cached", :vcr do
    visit root_path

    fill_in "Type your zip code here", with: "10001"
    click_on "Search"

    expect(page).not_to have_text("Cached result")

    fill_in "Type your zip code here", with: "10001"
    click_on "Search"

    expect(page).to have_text("Cached result")
  end

  it "displays an error when the API fails" do
    stub_request(:get, /api.weatherapi.com/).to_timeout

    visit root_path
    fill_in "Type your zip code here", with: "10001"
    click_on "Search"

    expect(page).to have_text("It wasn't possible to get forecast: Timeout error.")
  end
end
