# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeatherService do
  let(:api_key) { "your_api_key" }
  let(:lat) { 42.1641795 }
  let(:lon) { -72.4586552 }
  let(:weather_service) { described_class.new(api_key: api_key, lat: lat, lon: lon) }

  describe ".new" do
    context "when valid parameters are provided" do
      it "initializes the service without errors" do
        expect { weather_service }.not_to raise_error
      end
    end

    context "when API key is missing" do
      let(:api_key) { nil }

      it "raises an ArgumentError" do
        expect { weather_service }.to raise_error(ArgumentError, "API key is required")
      end
    end

    context "when latitude is not a float" do
      let(:lat) { "invalid_lat" }

      it "raises an ArgumentError" do
        expect { weather_service }.to raise_error(ArgumentError, "Latitude is required float value")
      end
    end

    context "when longitude is not a float" do
      let(:lon) { "invalid_lon" }

      it "raises an ArgumentError" do
        expect { weather_service }.to raise_error(ArgumentError, "Longitude is required float value")
      end
    end
  end

  describe ".call" do
    it "calls the instance method #call" do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.call(api_key: api_key, lat: lat, lon: lon)
    end
  end

  describe "#call" do
    before do
      current_weather_json = File.read(Rails.root.join("spec", "support", "fixtures", "openweathermap_org", "current_weather_response.json"))
      forecast_weather_json = File.read(Rails.root.join("spec", "support", "fixtures", "openweathermap_org", "forecast_weather_response.json"))

      allow(described_class).to receive(:get).with("/weather", anything).and_return(JSON.parse(current_weather_json))
      allow(described_class).to receive(:get).with("/forecast", anything).and_return(JSON.parse(forecast_weather_json))
    end

    it "returns an OpenStruct with current and forecast weather" do
      result = weather_service.call
      expect(result).to be_an(OpenStruct)
      expect(result.to_h).to have_key(:success?)
      expect(result.success?).to eq(true)
      expect(result.to_h).to have_key(:current)
      expect(result.to_h).to have_key(:forecast)
      expect(result.current.temp).to eq(284.2) # Pulled from the fixture file: current_weather_response.json:17
      date_value = Time.at(1661797200).to_date # Pulled from the fixture file: forecast_weather_response.json:8
      expect(result.forecast[date_value].first.temp).to eq(296.76) # Pulled from the fixture file: forecast_weather_response.json:10
    end
  end

  describe "#call with failed response from current_weather" do
    before do
      error_response_json = File.read(Rails.root.join("spec", "support", "fixtures", "openweathermap_org", "error_response.json"))
      forecast_weather_json = File.read(Rails.root.join("spec", "support", "fixtures", "openweathermap_org", "forecast_weather_response.json"))
      allow(described_class).to receive(:get).with("/weather", anything).and_return(JSON.parse(error_response_json))
      allow(described_class).to receive(:get).with("/forecast", anything).and_return(JSON.parse(forecast_weather_json))
    end

    it "returns success? false" do
      result = weather_service.call
      expect(result).to be_an(OpenStruct)
      expect(result.to_h).to have_key(:success?)
      expect(result.to_h).to have_key(:error)
      expect(result.success?).to eq(false)
    end
  end

  describe "#get_current" do
    let(:response) { { "cod" => 200, "main" => { "temp" => 75.0 }, "weather" => [ { "description" => "clear sky", "icon" => "01d" } ] } }

    before do
      allow(described_class).to receive(:get).with("/weather", anything).and_return(response)
    end

    it "returns the current weather details" do
      result = weather_service.send(:get_current)
      expect(result.temp).to eq(75.0)
      expect(result.description).to eq("clear sky")
      expect(result.icon_url).to eq("http://openweathermap.org/img/w/01d.png")
    end
  end

  describe "#get_forecast" do
    let(:response) { { "cod" => 200, "list" => [ { "dt" => Time.now.to_i, "main" => { "temp" => 75.0 }, "weather" => [ { "description" => "clear sky", "icon" => "01d" } ] } ] } }

    before do
      allow(described_class).to receive(:get).with("/forecast", anything).and_return(response)
    end

    it "returns the forecast weather details grouped by date" do
      result = weather_service.send(:get_forecast)
      expect(result[Date.today].first.temp).to eq(75.0)
      expect(result[Date.today].first.description).to eq("clear sky")
      expect(result[Date.today].first.icon_url).to eq("http://openweathermap.org/img/w/01d.png")
    end
  end
end
