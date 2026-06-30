# app/controllers/api

The REST API surface — 137 `.rb` controller files serving the JSON API consumed by the web SPA and third-party clients; the full route map lives in `config/routes/api.rb`. `Source: app/controllers/api`, `Source: config/routes/api.rb`

## Key files

- `base_controller.rb` — shared base providing authentication, error handling, rate-limit headers, and pagination for every API controller (`class Api::BaseController < ApplicationController`, including `Api::ErrorHandling`, `Api::Pagination`, and related concerns). `Source: app/controllers/api/base_controller.rb:3`, `Source: app/controllers/api/base_controller.rb:7-12`
- `v1/` — the primary API namespace (113 controllers). `Source: app/controllers/api/v1`
- `v2/` — revised endpoints that supersede some `v1` shapes (11 controllers). `Source: app/controllers/api/v2`
- `v1_alpha/` — experimental/unstable endpoints (1 controller). `Source: app/controllers/api/v1_alpha`
- `config/routes/api.rb` — the route map for every endpoint in this namespace. `Source: config/routes/api.rb:3`

## Conventions

- **Versioned namespaces (`v1` / `v2` / `v1_alpha`)** — routes nest under `namespace :api` and then under a per-version namespace. **Why:** pinning a version lets the API evolve — introducing `v2` response shapes or trialing `v1_alpha` endpoints — without breaking existing clients that depend on `v1`. `Source: config/routes/api.rb:3`, `Source: config/routes/api.rb:8`, `Source: config/routes/api.rb:29`, `Source: config/routes/api.rb:346`
- **Doorkeeper OAuth scope enforcement** — endpoints gate access on specific OAuth scopes, e.g. `before_action -> { doorkeeper_authorize! :write, :'write:statuses' }`, with the shared unauthorized/forbidden responses defined on the base controller. **Why:** binding each token to only the scopes the user explicitly granted enforces least privilege, so a third-party application can perform only the actions it was approved for. `Source: app/controllers/api/v1/statuses_controller.rb:8`, `Source: app/controllers/api/base_controller.rb:23-28`

Companion artifacts from the same documentation run: [`../../models/README.md`](../../models/README.md), [`../../services/README.md`](../../services/README.md), [`../../workers/README.md`](../../workers/README.md), [`../../lib/activitypub/README.md`](../../lib/activitypub/README.md), [`../../../docs/feature-component-map.md`](../../../docs/feature-component-map.md), [`../../../docs/deployment-topology.md`](../../../docs/deployment-topology.md), [`../../../docs/external-integration-map.md`](../../../docs/external-integration-map.md).
