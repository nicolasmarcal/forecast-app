# Forecast App
App developed using Ruby 4.0.9 and Rails 8.1.0 to retrieve forecast data from a given zip code.

## Architecture and Technical decisions
1. Cache with Redis (`Rails.cache`)
- Decision: Use Redis as backend to `Rails.cache` as a TTL (time to live) of 30 minutes
- WHY: It decouples state from the web tier (stateless web tier). All workers and containers share the same in-memory source of truth, maximizing the cache hit rate and allowing the system to survive restarts of Rails processes. Thats why use Redis instead of `:memory_store`

2. Use of `ActiveModel::Model` instead of an `ApplicationRecord` model
- We have validation methods, but we don't need to persist on the database

3. Libraries `Net::HTTP` and `JSON` to external integration
- Decision: Comunication with WeatherAPI inside a Service object dedicated
- WHY: Minimal dependency footprint. Relying on Ruby's standard library instead of third-party wrappers (Faraday or HTTParty) eliminates external transitive dependencies, reduces explosure to supply-chain vulnerabilities and avoids dependency lock-in future Rails upgrades.

4. Hotwire / Turbo streams
- WHY: send form asynchronous, we don't need to reload the page to show results. The user have a best experience

5. Rails Credentials
- WHY: URL base and API key encrypted on `Rails.application.credentials`, avoiding explosure.

## Running project
### Prerequisites
- Docker and Docker compose
- master.key (sent by email)

### Step by step
1. Clone repository
2. Rename `config/master.key.sample` to `config/master.key` and set the master key (sent by email)
3. run `docker compose up --build`
4. Access `localhost:3000` and inform an american zip code.

### Specs
The test suit was build with RSpec, covering models, requests, services and flows (system specs)
- VCR & WebMock: requests are recorded in cassetes filtering sensitive data. Scenarios of failure are covered (timeout, errors, rate limits)
- Cache expiration tested with `ActiveSupport::Testing::TimeHelpers`
- CI with rubocop

To run the suit inside the container:
```
docker compose exec web bundle exec rspec
```

