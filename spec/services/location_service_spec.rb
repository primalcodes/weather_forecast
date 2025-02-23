require "rails_helper"

RSpec.describe LocationService do
  describe "#call" do
    context "with a valid address of a multi-zipcode city" do
      let(:address) { "Albany, NY" }

      before do
        large_area_address = File.read(Rails.root.join("spec", "support", "fixtures", "geocode", "large_area_address.json"))

        response = [ OpenStruct.new(data: JSON.parse(large_area_address)) ]
        allow(Geocoder).to receive(:search).and_return(response)
      end
      it "returns the location details of a large city, no zipcode" do
        location = LocationService.call(address: address)

        expect(location.place_id).to be_a_kind_of(Integer)
        expect(location.lat).to eq(42.6511674)
        expect(location.lon).to eq(-73.754968)
        expect(location.name).to eq("City of Albany, Albany County, New York, United States")
        expect(location.zip_code).to be_nil
      end
    end

    context "with a valid address of a small town (single zipcode)" do
      let(:address) { "123 Chapel Street, Mount Morris, NY" }

      before do
        small_area_address = File.read(Rails.root.join("spec", "support", "fixtures", "geocode", "small_area_address.json"))

        response = [ OpenStruct.new(data: JSON.parse(small_area_address)) ]
        allow(Geocoder).to receive(:search).and_return(response)
      end
      it "returns the location details" do
        location = LocationService.call(address: address)

        expect(location.zip_code).to eq("14510")
      end
    end

    context "with an empty address" do
      let(:address) { "" }

      it "raises an ArgumentError" do
        expect { LocationService.call(address: address) }.to raise_error(ArgumentError, "Address is required")
      end
    end

    context "with a nil address" do
      let(:address) { nil }

      it "raises an ArgumentError" do
        expect { LocationService.call(address: address) }.to raise_error(ArgumentError, "Address is required")
      end
    end

    context "when provided an invalid address" do
      let(:address) { "InvalidAddress" }

      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it "raises returns a failed response" do
        location = LocationService.call(address: address)

        expect(location.success?).to eq(false)
        expect(location.error).to eq("Failed to geocode address")
      end
    end
  end
end
