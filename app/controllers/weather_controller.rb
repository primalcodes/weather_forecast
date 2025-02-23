class WeatherController < ApplicationController
  def index
    @cached_weather = true
    if params[:address].blank?
      return
    end

    # Get location details
    @location = LocationService.call(address: params[:address])
    if !@location.success?
      flash.now[:alert] = @location.error

      return
    end

    # Prefer zip_code over place_id as it is more specific and commonly used
    # Some locations may not have a zip_code returned.
    location_cache_key = @location&.zip_code || @location&.place_id

    # Get weather data for the location
    @cached_weather = true
    weather_error_message = nil
    @weather_data = Rails.cache.fetch(location_cache_key, expires_in: ENV["CACHE_EXPIRATION_MINS"].to_i.minutes, skip_nil: true) do
      @cached_weather = false
      resp = weather_data(@location)
      if resp.success?
        resp
      else
        weather_error_message = resp.error
        nil # Don't cache the error response
      end
    end

    if @weather_data.nil?
      flash.now[:alert] = weather_error_message
    end

    render "index"
  end

  private

  def weather_data(location)
    weather_svc = WeatherService.new(
      api_key: ENV["OPENWEATHER_API_KEY"],
      lat: location.lat,
      lon: location.lon
    )

    weather_svc.call
  end
end
