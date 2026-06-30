# app/services

The Rails **write/command path**: **77 service objects** (`Source: app/services/`) that encapsulate discrete business workflows and are invoked by controllers and background workers. Each inherits from `BaseService` (`Source: app/services/base_service.rb:3`), whose single-entrypoint contract `def call(*)` raises `NotImplementedError` until a subclass overrides it (`Source: app/services/base_service.rb:9-11`). Services are called directly from controllers (`Source: app/controllers/api/v1/statuses_controller.rb:31`) and from Sidekiq workers (`Source: app/workers/refollow_worker.rb:23`).

## Key files

| File                          | Role                                                    | Source                                             |
| ----------------------------- | ------------------------------------------------------- | -------------------------------------------------- |
| `post_status_service.rb`      | Creates a new status and triggers its distribution.     | `Source: app/services/post_status_service.rb`      |
| `fan_out_on_write_service.rb` | Pushes a new status into follower timelines/streams.    | `Source: app/services/fan_out_on_write_service.rb` |
| `follow_service.rb`           | Establishes a follow relationship (local or federated). | `Source: app/services/follow_service.rb`           |
| `process_mentions_service.rb` | Resolves and links mentions within a status.            | `Source: app/services/process_mentions_service.rb` |

## Conventions

- **Single `#call` command-object interface.** Every `*_service.rb` exposes exactly one public entrypoint, `#call`; the base class enforces this by raising `NotImplementedError` from its default `def call(*)` (`Source: app/services/base_service.rb:9-11`). Signatures vary by domain — e.g. `def call(account, options = {})` (`Source: app/services/post_status_service.rb:42`), `def call(status, options = {})` (`Source: app/services/fan_out_on_write_service.rb:12`), and `def call(source_account, target_account, options = {})` (`Source: app/services/follow_service.rb:18`). **Why:** a uniform command-object interface keeps services predictable and trivially callable from web, API, and background contexts, so no caller has to learn a bespoke per-service API.
- **Services orchestrate models and enqueue workers; they hold no HTTP or view logic.** For example, `PostStatusService` persists the status, then hands asynchronous fan-out to Sidekiq via `DistributionWorker.perform_async(@status.id)` (`Source: app/services/post_status_service.rb:166`) and `ActivityPub::DistributionWorker.perform_async(@status.id)` (`Source: app/services/post_status_service.rb:168`). **Why:** keeping the request/response cycle out of services makes controllers thin and lets the identical business logic run unchanged from web, API, and Sidekiq job contexts.

---

Companion artifacts from the same documentation run: [`../models/README.md`](../models/README.md), [`../controllers/api/README.md`](../controllers/api/README.md), [`../workers/README.md`](../workers/README.md), [`../lib/activitypub/README.md`](../lib/activitypub/README.md), [`../../docs/feature-component-map.md`](../../docs/feature-component-map.md), [`../../docs/deployment-topology.md`](../../docs/deployment-topology.md), [`../../docs/external-integration-map.md`](../../docs/external-integration-map.md).
