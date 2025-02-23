# frozen_string_literal: true

require "httparty"
require "ostruct"

# WeatherService is a service class that leverages the OpenWeatherMap API
# to fetch current weather data for a given location (lat/lon).
#
# @see OpenWeatherMap API documentation: https://openweathermap.org/current
#
# @example
#   weather_service = WeatherService.new(api_key: "your_api_key", lat: 42.1641795, lon: -72.4586552)
#   current_weather = weather_service.get_current
#
# @return [OpenStruct] with the following attributes:
# - current: An object containing the current weather details
#   - date: The date and time of the weather data
#   - description: A brief description of the weather (e.g., "clear sky")
#   - icon_url: A URL to the weather icon
#   - temp: The current temperature in Fahrenheit
#   - high_temp: The high temperature in Fahrenheit
#   - low_temp: The low temperature in Fahrenheit
#   - location: The name of the location
# - forecast: A hash containing the forecasted weather data grouped by date
#
# @raise [ArgumentError] if the API key, latitude, or longitude is nil or empty.
# @raise [ArgumentError] if the latitude or longitude is not a float value.
class WeatherService
  include HTTParty

  base_uri "https://api.openweathermap.org/data/2.5"

  # Initializes the WeatherService with the given API key, latitude, and longitude.
  #
  # @param api_key [String] the OpenWeatherMap API key.
  # @param lat [Float] the latitude of the location.
  # @param lon [Float] the longitude of the location.
  def initialize(api_key:, lat:, lon:)
    raise ArgumentError, "API key is required" if api_key.nil? || api_key.empty?
    raise ArgumentError, "Latitude is required float value" if lat.nil? || !lat.is_a?(Float)
    raise ArgumentError, "Longitude is required float value" if lon.nil? || !lon.is_a?(Float)

    @options = { query: { APPID: api_key, lat:, lon:, units: "imperial" } }
  end

  # Class method to get the current weather for a given location.
  #
  # @param api_key [String] the OpenWeatherMap API key.
  # @param lat [Float] the latitude of the location.
  # @param lon [Float] the longitude of the location.
  #
  # @param same as #initialize
  # @return same as #call
  def self.call(**kwargs)
    new(**kwargs).call
  end

  # Instance method to get the current and forecast weather for a given location.
  #
  # @return [OpenStruct] an object containing the weather details.
  # - success?: A boolean indicating if the weather data was successfully fetched
  # - current: An object containing the current weather details
  # - forecast: A hash containing the forecasted weather data grouped by date
  # - error: The error message if fetching weather fails
  def call
    current_weather = get_current
    return failure_response("Failed to fetch current weather") unless current_weather

    forecast_weather = get_forecast
    return failure_response("Failed to fetch forecast weather") unless forecast_weather

    OpenStruct.new(
      success?: true,
      current: current_weather,
      forecast: forecast_weather
    )
  end

  private

  # Instance method to get the current weather for a given location.
  #
  # @return [OpenStruct] an object containing the weather details on success.
  # @return nil on failure
  def get_current
    resp = self.class.get("/weather", @options)
    if resp["cod"].to_i != 200
      Rails.logger.error("Failed to fetch current weather: #{resp["message"]})")
      return nil
    end

    build_weather(resp)
  end

  # Instance method to get the weather forecast for a given location.
  #
  # @return [OpenStruct] an object containing the weather details on success.
  # @return nil on failure.
  def get_forecast
    resp = self.class.get("/forecast", @options)
    if resp["cod"].to_i != 200
      Rails.logger.error("Failed to fetch weather forecast: #{resp["message"]}")
      return nil
    end

    data = resp["list"].map do |weather|
      build_weather(weather)
    end

    data.group_by { |weather| weather.date.to_date }
  end

  # Builds a weather object from the API response.
  #
  # @param resp [Hash] the API response.
  # @return [OpenStruct] an object containing the weather details.
  # @see https://openweathermap.org/current#example_JSON
  # @see https://openweathermap.org/forecast5#JSON
  def build_weather(resp = {}, date = nil)
    date = resp.has_key?("dt") ? Time.at(resp["dt"]) : Time.now

    ::OpenStruct.new(
      date:,
      description: resp.dig("weather", 0, "description"),
      icon_url: icon_url(resp.dig("weather", 0, "icon")),
      temp: resp.dig("main", "temp"),
      high_temp: resp.dig("main", "temp_max"),
      low_temp: resp.dig("main", "temp_min"),
      location: resp.dig("name")
    )
  end

  # Returns the URL for the weather icon.
  #
  # @param icon [String] the icon code.
  # @return [String] the URL for the weather icon.
  def icon_url(icon)
    return nil unless icon

    "http://openweathermap.org/img/w/#{icon}.png"
  end

  def failure_response(msg)
    OpenStruct.new(success?: false, error: msg)
  end
end
