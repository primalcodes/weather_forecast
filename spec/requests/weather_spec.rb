require 'rails_helper'

RSpec.describe "Weathers", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/weather"
      expect(response).to have_http_status(:success)
    end

    it "returns the weather data for a location when valid address is provided" do
      # Setup the location service
      large_area_address = File.read(Rails.root.join("spec", "support", "fixtures", "geocode", "large_area_address.json"))
      location_response = [ OpenStruct.new(data: JSON.parse(large_area_address)) ]
      allow(Geocoder).to receive(:search).and_return(location_response)
      address_param = location_response.first.data["name"]

      # Setup the weather service
      current_weather_json = File.read(Rails.root.join("spec", "support", "fixtures", "openweathermap_org", "current_weather_response.json"))
      forecast_weather_json = File.read(Rails.root.join("spec", "support", "fixtures", "openweathermap_org", "forecast_weather_response.json"))
      allow(WeatherService).to receive(:get).with("/weather", anything).and_return(JSON.parse(current_weather_json))
      allow(WeatherService).to receive(:get).with("/forecast", anything).and_return(JSON.parse(forecast_weather_json))

      # Make the request
      get "/weather", params: { address: address_param }

      # Check for the location name
      expect(response.body).to include(address_param)

      # Check the current weather
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Current")
      expect(response.body).to include("Moderate Rain")
      expect(response.body).to include("284")

      # Check the forecast
      the_time = Time.at(1661797200)
      expect(response.body).to include(the_time.strftime("%A")) # Day of the week ex. "Wednesday"
      expect(response.body).to include(the_time.strftime("%-I:%M%P")) # Day of the week ex. "Wednesday"
      expect(response.body).to include("8:00am")
      expect(response.body).to include("296")
    end

    # it "returns an error message when invalid address is provided" do
    #   # allow(LocationService).to receive(:call).and_return(OpenStruct.new(success?: false, error: "Failed to geocode address"))

    #   get "/weather", params: { address: "InvalidAddress" }

    #   expect(response).to have_http_status(:success)
    #   expect(response.body).to include("Failed to geocode address")
    # end
  end
end
