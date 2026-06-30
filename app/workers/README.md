# app/workers

The **Sidekiq asynchronous job layer**: 56 top-level worker classes plus subfolders (`activitypub/`, `admin/`, `concerns/`, `fasp/`, `import/`, `scheduler/`, `web/`, `webhooks/`) that perform timeline fan-out, ActivityPub federation delivery, and scheduled maintenance off the synchronous request path. Queue weights and cron schedules are defined in `config/sidekiq.yml`. `Source: app/workers`, `Source: config/sidekiq.yml`

## Key files

| File | Role |
|------|------|
| `activitypub/delivery_worker.rb` | Delivers a single signed ActivityPub payload to one remote inbox. `Source: app/workers/activitypub/delivery_worker.rb` |
| `feed_insert_worker.rb` | Inserts a status into a follower or list timeline (home-feed fan-out). `Source: app/workers/feed_insert_worker.rb` |
| `push_update_worker.rb` | Publishes a rendered status update to a Redis timeline channel consumed by the streaming service. `Source: app/workers/push_update_worker.rb` |
| `scheduler/` | Directory of cron-style recurring jobs (e.g. `indexing_scheduler.rb`, `vacuum_scheduler.rb`, `pghero_scheduler.rb`). `Source: app/workers/scheduler` |

## Conventions

- **Queues are weighted by priority, not equal.** `config/sidekiq.yml` declares `[default, 8] [push, 6] [ingress, 4] [mailers, 2] [pull] [scheduler] [fasp]`. **Why:** the weights let latency-sensitive work (e.g. the `push` queue used by federation delivery) be polled more often than bulk/backfill work (`pull`), so user-visible actions are not starved by large backfills. `Source: config/sidekiq.yml:3-10`
- **`scheduler/` holds cron jobs, not request-triggered work.** The `:scheduler:` / `:schedule:` block binds `Scheduler::*` classes to `interval:` / `every:` / `cron:` triggers (e.g. `indexing_scheduler`, `vacuum_scheduler`, `pghero_scheduler`). **Why:** periodic reconciliation and maintenance run on a built-in timer, so the deployment needs no external system cron. `Source: config/sidekiq.yml:12-82`
- **Jobs must be safe to run more than once, and long scheduled jobs take a lock.** Delivery sets `sidekiq_options queue: 'push', retry: 16, dead: false`; schedulers set `sidekiq_options retry: 0, lock: :until_executed`. **Why:** Sidekiq executes a job at least once and may retry it, so a re-run must not corrupt state; the `:until_executed` lock stops a slow scheduled run from overlapping its next tick. `Source: app/workers/activitypub/delivery_worker.rb:11`, `Source: app/workers/scheduler/indexing_scheduler.rb:8`
- **Real-time updates hand off to the streaming tier via Redis pub/sub.** `push_update_worker.rb` mixes in `Redisable` and calls `redis.publish(@timeline_id, message)`. **Why:** the Rails workers publish to Redis channels that the standalone Node `streaming` service subscribes to, decoupling real-time delivery from the Rails process. `Source: app/workers/push_update_worker.rb:5`, `Source: app/workers/push_update_worker.rb:33`

---

Companion module READMEs: [`app/models`](../models/README.md), [`app/services`](../services/README.md), [`app/controllers/api`](../controllers/api/README.md), [`app/lib/activitypub`](../lib/activitypub/README.md); see also [`docs/feature-component-map.md`](../../docs/feature-component-map.md), [`docs/deployment-topology.md`](../../docs/deployment-topology.md), and [`docs/external-integration-map.md`](../../docs/external-integration-map.md).
