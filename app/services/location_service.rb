# frozen_string_literal: true

require "geocoder"
require "ostruct"


# LocationService is a service class responsible for geocoding an address
# and returning its location details.
#
# @example
#   location = LocationService.call(address: "123 Chapel Street, Mount Morris, NY")
#
# @return [OpenStruct] with the following location attributes:
#  - place_id: Place ID of the address
#  - lat: Latitude of the address
#  - lon: Longitude of the address
#  - name: Display name of the address
#  - zip_code: Zip code of the address
#  - success?: A boolean indicating if the geocoding was successful
#  - error: An error message if the geocoding failed
#
# @raise [ArgumentError] if the address is nil or empty.
class LocationService
  # Initializes the LocationService with the given address.
  #
  # @param address [String] the address to be geocoded.
  def initialize(address:)
    @address = address

    raise ArgumentError, "Address is required" if @address.nil? || @address.empty?
  end

  # Class method to get the location details for a given address.
  #
  # @param same as #initialize
  # @return same as #call
  def self.call(**kwargs)
    new(**kwargs).call
  end

  # Instance method to get the location details for the initialized address.
  def call
    resp = Geocoder.search(@address).first&.data
    return failure_response("Failed to geocode address") if resp.nil?

    OpenStruct.new(
      success?: true,
      place_id: resp["place_id"],
      lat: resp["lat"].to_f,
      lon: resp["lon"].to_f,
      name: resp["display_name"],
      zip_code: resp.dig("address", "postcode")
    )
  end

  private

  def failure_response(msg)
    OpenStruct.new(success?: false, error: msg)
  end
end
