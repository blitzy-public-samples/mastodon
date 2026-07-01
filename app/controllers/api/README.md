# app/controllers/api

The REST API surface — controllers serving the JSON API. The primary REST route map lives in `config/routes/api.rb`; additional `api/fasp` endpoints are defined separately in `config/routes/fasp.rb`, which the main router draws alongside `api`. `Source: config/routes/api.rb:3`, `Source: config/routes.rb:238-240`, `Source: config/routes/fasp.rb:3-4`

## Key files

- `base_controller.rb` — shared base providing authentication, error handling, rate-limit headers, and pagination for the main API controller tree (`class Api::BaseController < ApplicationController`, including `Api::ErrorHandling`, `Api::Pagination`, and related concerns). The `api/fasp` controllers are the exception: they descend from their own `Api::Fasp::BaseController < ApplicationController`. `Source: app/controllers/api/base_controller.rb:3`, `Source: app/controllers/api/base_controller.rb:7-12`, `Source: app/controllers/api/fasp/base_controller.rb:3`
- `v1/` — the `v1` API controllers, mounted under `namespace :v1`. `Source: config/routes/api.rb:29`
- `v2/` — the `v2` API controllers, mounted under `namespace :v2`. `Source: config/routes/api.rb:346`
- `v1_alpha/` — endpoints the route file labels "Experimental", mounted under `namespace :v1_alpha`. `Source: config/routes/api.rb:7-8`
- `config/routes/api.rb` — the primary REST route map for this namespace; `api/fasp` routes live in `config/routes/fasp.rb`. `Source: config/routes/api.rb:3`, `Source: config/routes/fasp.rb:3-4`

## Conventions

- **Versioned namespaces (`v1` / `v2` / `v1_alpha`)** — routes nest under `namespace :api` and then under a per-version namespace. **Why:** pinning a version lets the API evolve — introducing `v2` response shapes or trialing `v1_alpha` endpoints — without breaking existing clients that depend on `v1`. `Source: config/routes/api.rb:3`, `Source: config/routes/api.rb:8`, `Source: config/routes/api.rb:29`, `Source: config/routes/api.rb:346`
- **Doorkeeper OAuth scope enforcement** — endpoints gate access on specific OAuth scopes, e.g. `before_action -> { doorkeeper_authorize! :write, :'write:statuses' }`, with the shared unauthorized/forbidden responses defined on the base controller. **Why:** binding each token to only the scopes the user explicitly granted enforces least privilege, so a third-party application can perform only the actions it was approved for. `Source: app/controllers/api/v1/statuses_controller.rb:8`, `Source: app/controllers/api/base_controller.rb:23-28`

Companion artifacts from the same documentation run: [`../../models/README.md`](../../models/README.md), [`../../services/README.md`](../../services/README.md), [`../../workers/README.md`](../../workers/README.md), [`../../lib/activitypub/README.md`](../../lib/activitypub/README.md), [`../../../docs/feature-component-map.md`](../../../docs/feature-component-map.md), [`../../../docs/deployment-topology.md`](../../../docs/deployment-topology.md), [`../../../docs/external-integration-map.md`](../../../docs/external-integration-map.md).
