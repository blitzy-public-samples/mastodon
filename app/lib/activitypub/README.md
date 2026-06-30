# app/lib/activitypub

The **ActivityPub federation protocol** implementation — 29 Ruby files: 8 top-level files plus the `activity/` subfolder (16 inbound activity handlers) and the `parser/` subfolder (5 inbound object parsers). This directory is the federation backbone and works alongside the sibling directories that complete the picture: `app/controllers/activitypub` (inbound HTTP endpoints), `app/serializers/activitypub` (outbound document shapes), and `app/workers/activitypub` (async delivery). `Source: app/lib/activitypub`

## Key files

| File | Role |
|------|------|
| `activity.rb` | Abstract inbound activity base class; a factory that selects a concrete handler per activity type. `Source: app/lib/activitypub/activity.rb` |
| `adapter.rb` | JSON-LD serialization adapter that wraps serialized output with an `@context`. `Source: app/lib/activitypub/adapter.rb` |
| `serializer.rb` | Base ActivityPub serializer that declares named JSON-LD contexts / context extensions. `Source: app/lib/activitypub/serializer.rb` |
| `linked_data_signature.rb` | Linked-Data (RsaSignature2017) signing and verification of JSON-LD payloads. `Source: app/lib/activitypub/linked_data_signature.rb` |
| `tag_manager.rb` | Canonical URI/URL generation and inbound URI→record resolution for federated identifiers. `Source: app/lib/activitypub/tag_manager.rb` |

## Conventions

- **Inbound activities are dispatched to per-verb handler subclasses.** `ActivityPub::Activity.factory` calls `klass_for(json)`, a case statement that maps the AP `type` (`Create`, `Announce`, `Delete`, `Follow`, `Like`, `Block`, `Update`, `Undo`, `Accept`, `Reject`, `Flag`, `Add`, `Remove`, `Move`, `QuoteRequest`, `FeatureRequest`) to a handler class in the `activity/` subfolder (`create.rb`, `announce.rb`, `follow.rb`, …); the base `#perform` raises `NotImplementedError`, so each subclass must override it. **Why:** one focused handler per activity verb keeps protocol handling isolated and independently testable. `Source: app/lib/activitypub/activity.rb:19`, `Source: app/lib/activitypub/activity.rb:30-62`
- **Outbound objects are JSON-LD serialized through the adapter + serializer pair.** `ActivityPub::Adapter` (a subclass of `ActiveModelSerializers::Adapter::Base`) builds the `@context` and merges it into the serialized hash, while `ActivityPub::Serializer` (a subclass of `ActiveModel::Serializer`) declares the named contexts (`self.context`) and context extensions (`self.context_extensions`). **Why:** federated peers require valid JSON-LD documents that carry an `@context`. `Source: app/lib/activitypub/adapter.rb:3`, `Source: app/lib/activitypub/adapter.rb:23`, `Source: app/lib/activitypub/serializer.rb:3`
- **Federated requests are authenticated by HTTP Signatures and Linked-Data signatures.** `ActivityPub::LinkedDataSignature` verifies (`verify_actor!`) and signs (`sign!`) the JSON-LD payload, while inbound controllers `include SignatureVerification` for HTTP Signature checks. **Why:** federation is trustless server-to-server between independent instances, so each request's origin must be cryptographically proven. `Source: app/lib/activitypub/linked_data_signature.rb:36`, `Source: app/controllers/activitypub/base_controller.rb:4`

---

*Companion artifacts from this run: [`app/models/README.md`](../../models/README.md) · [`app/services/README.md`](../../services/README.md) · [`app/controllers/api/README.md`](../../controllers/api/README.md) · [`app/workers/README.md`](../../workers/README.md) · [`docs/feature-component-map.md`](../../../docs/feature-component-map.md) · [`docs/deployment-topology.md`](../../../docs/deployment-topology.md) · [`docs/external-integration-map.md`](../../../docs/external-integration-map.md)*
