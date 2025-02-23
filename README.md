# Weather Forecast

## About
Simple weather forcasting application designed to take a user provided input (address) and return both the
current weather and forecast for the given address.  From a development standpoint, using Rdoc style documentation 
allows others to follow with clarity what the code does.  Rspec is used to limit bloat and prevent regressions.

1. The application takes a given address and attempts to geocode it to retrieve its latitude/longitude coordinates.
2. With the coordinates, the WeatherService will make 2 API calls to satisfy the stakeholder requirements of viewing both
the current weather and the upcoming forecast.
3. Caching is performed on an initial request (per zipcode) and leveraged for 30 minutes for subsequent requests of the same zipcode.

### Tech Stack
- Ruby on Rails 8.0.1
- Ruby 3.2.2
- Redis
- Rspec
- Bootstrap 5.3

### External Dependencies
- Geocoding service via [geocoder gem](https://github.com/alexreisner/geocoder)
- [Weather API](openweathermap.org): Requires an API Key.  This service provides the required functionality for free with limitations.

## Install

### Clone the repository

```shell
git clone git@github.com:primalcodes/weather_forecast.git
cd weather_forecast
```

### Check your Ruby version

```shell
ruby -v
```

The ouput should start with something like `ruby 3.2.2`

If not, install the right ruby version using [rbenv](https://github.com/rbenv/rbenv) (it could take a while):

```shell
rbenv install 3.2.2
```

### Redis
Leveraged for caching in the geocoder gem and weather api responses.
```shell
brew install redis
```

### Install dependencies

Using [Bundler](https://github.com/bundler/bundler):

```shell
bundle
```

### Foreman
Usage of foreman to run all services needed for app
```shell
gem install foreman
```

### Set environment variables
Copy file `.env.sample` to `.env` and update to include your API key.

```shell
cp .env.sample .env
```

## Serve

```shell
bin/dev
```

## Performance Considerations

### Location/Weather API
Consider using [Google Place Autocomplete](https://developers.google.com/maps/documentation/javascript/place-autocomplete) search UI to reduce invalid address searches and improve on quality of results.

### RackAttack
Rack middleware for blocking & throttling abusive requests. Limit unnecessary API calls to LocationService and WeatherService. [source](https://github.com/rack/rack-attack).  Currently, the application leverages of Redis for both geocoding and weather api responses help mitigate this.
