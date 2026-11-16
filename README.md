# Forecast App
App developed using Ruby 4.0.9 and Rails 8.1.0 to retrieve forecast data from a given zip code.

## Architecture and Technical decisions
1. Cache with Redis (`Rails.cache`)
- Normalization: We normalize zip codes using `ZipCodeNormalizable` concern, removing spaces and special characters (so `"10001"`, `" 10001 "` and `"1.0 001"` hit the same cache key `weather:10001`)
- Concurrency: Removed `Rails.cache.exist?` check to avoid TOCTOU race conditions and added `race_condition_ttl: 10.seconds` to prevent cache stampedes when popular keys expire
- Decision: Use Redis as backend to `Rails.cache` as a TTL (time to live) of 30 minutes
- WHY: It decouples state from the web tier (stateless web tier). All workers and containers share the same in-memory source of truth, maximizing the cache hit rate and allowing the system to survive restarts of Rails processes. Thats why use Redis instead of `:memory_store`

2. Use of `ActiveModel::Model` instead of an `ApplicationRecord` model
- We have validation methods, but we don't need to persist on the database

3. Libraries `Net::HTTP` and `JSON` to external integration
- Separation & DI: Isolated HTTP calls inside `WeatherApiClient` and injected it into `WeatherService` (`client: WeatherApiClient.new`), making easier to mock on unit tests and keeping cache logic decoupled from network transport
- Error handling & Value Object: Replaced generic `rescue StandardError` with specific exceptions (`TimeoutError`, `RateLimitError`, `LocationNotFoundError`, `MalformedResponseError`, `UpstreamError`) returning an immutable `ForecastResult` (`Data.define`) with the right HTTP status
- Decision: Comunication with WeatherAPI inside a Service object dedicated
- WHY: Minimal dependency footprint. Relying on Ruby's standard library instead of third-party wrappers (Faraday or HTTParty) eliminates external transitive dependencies, reduces explosure to supply-chain vulnerabilities and avoids dependency lock-in future Rails upgrades.

4. Hotwire / Turbo streams
- WHY: send form asynchronous, we don't need to reload the page to show results. The user have a best experience

5. Rails Credentials
- WHY: URL base and API key encrypted on `Rails.application.credentials`, avoiding explosure.

6. JSON API & Multi-stage Docker
- WHY: Added content negotiation (`respond_to`) on `POST /forecast` so external clients can consume the JSON API directly without browser headers, returning semantic HTTP errors (`422`, `429`, `502`, `504`). Also refactored `Dockerfile` with `development` and `production` targets so `docker compose up` boots with all dev/test gems available

## Running project
### Prerequisites
- Docker and Docker compose
- master.key (sent by email)

### Step by step
1. Clone repository
2. Rename `config/master.key.sample` to `config/master.key` and set the master key (sent by email)
3. run `docker compose up --build`
4. Access `localhost:3000` and inform an american zip code.

### Using the JSON API
You can also query the forecast endpoint directly via JSON:
```bash
curl -X POST http://localhost:3000/forecast \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"zip_code": "10001"}'
```

### Specs
The test suit was build with RSpec, covering models, requests, services and flows (system specs)
- VCR & WebMock: requests are recorded in cassetes filtering sensitive data. Scenarios of failure are covered (timeout, errors, rate limits)
- Cache expiration tested with `ActiveSupport::Testing::TimeHelpers`
- CI with rubocop

To run the suit inside the container:
```bash
docker compose exec -e RAILS_ENV=test web bundle exec rspec
```

