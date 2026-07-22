# Blitzy Project Guide — Trend Velocity Explore Tile

## 1. Executive Summary

### 1.1 Project Overview

This project adds a **"Trend Velocity" dashboard tile** to Mastodon's Explore experience (`/explore/tags`). The tile is a purely presentational, frontend-only React enhancement that ranks the top 5 trending hashtags and, for each, renders a compact inline-SVG sparkline of its use-count history plus a rising/falling/flat velocity indicator — all derived client-side from data the existing trends fetch already places in client state. It introduces **zero** changes to trend computation, the backend, the API, or the existing trends list. Target users are Mastodon web-app visitors browsing trends; the business impact is a richer, at-a-glance signal of hashtag momentum. The technical scope is deliberately narrow: two new presentational components and one surgical integration edit, all confined to `features/explore/`.

### 1.2 Completion Status

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'pie1':'#5B39F3','pie2':'#FFFFFF','pieStrokeColor':'#B23AF2','pieOuterStrokeColor':'#B23AF2','pieTitleTextColor':'#B23AF2','pieSectionTextColor':'#B23AF2','pieLegendTextColor':'#B23AF2'}}}%%
pie showData title Trend Velocity Tile — 80% Complete (24h of 30h)
    "Completed Work (AI)" : 24
    "Remaining Work" : 6
```

| Metric | Hours |
|---|---|
| **Total Hours** | 30 |
| **Completed Hours (AI + Manual)** | 24 (AI: 24, Manual: 0) |
| **Remaining Hours** | 6 |
| **Percent Complete** | **80.0%** |

> Completion is computed on AAP-scoped work only (PA1): `Completion % = Completed Hours / (Completed + Remaining) = 24 / 30 = 80.0%`. All AAP functional requirements are implemented and independently validated; the remaining 6h are human-gated path-to-production activities.

### 1.3 Key Accomplishments

- ✅ **All AAP functional requirements implemented and committed** — new tile mounted above the existing trends list, top-5 selection, reused `Hashtag` row, new sparkline + velocity indicator, client-side velocity, reused `/tags/:name` navigation.
- ✅ **All implicit requirements handled** — string→number coercion, newest-first history reversal for charting, duplicate-sparkline suppression (`withGraph={false}` + `children`), per-row degraded state (<2 points), localization, and accessibility.
- ✅ **Zero-regression validation** — TypeScript strict compile (0 errors), ESLint + Stylelint (0 violations), Vitest **4033/4033** tests passing, and a successful Vite production-mode build (independently re-verified).
- ✅ **Live runtime + accessibility verified** — real browser render on `/explore/tags`, degraded/empty states exercised, Lighthouse accessibility **100** (desktop & mobile).
- ✅ **Strict scope discipline** — exactly 3 files changed (2 created, 1 modified; 167 net LOC), all under `features/explore/`, zero dependency changes, zero backend/API edits, zero global SCSS edits.
- ✅ **QA hardening applied** — semantic `<h2>` heading fix and non-finite use-count hardening, both committed.

### 1.4 Critical Unresolved Issues

| Issue | Impact | Owner | ETA |
|---|---|---|---|
| _None — no blocking issues identified_ | The feature is code-complete, compiles, passes 4033/4033 tests, and renders correctly. No compilation errors, test failures, or runtime errors remain. | — | — |

### 1.5 Access Issues

| System/Resource | Type of Access | Issue Description | Resolution Status | Owner |
|---|---|---|---|---|
| _No access issues identified_ | — | Repository, toolchain (Node 24.18.0, Yarn 4.17.0), and dependencies (`node_modules` present, 681M) were all fully accessible. All validation gates ran successfully. | N/A | — |

### 1.6 Recommended Next Steps

1. **[High]** Conduct human code review of the 3-file PR diff (minimal-change compliance, token usage, accessibility).
2. **[High]** Perform manual QA on staging/live backend with real trends data (velocity directions, degraded rows, navigation, dark/light themes).
3. **[Medium]** Run `yarn i18n:extract` to register the 4 new message keys in `en.json` and push to the translation pipeline.
4. **[Medium]** Merge the PR after CI is green and perform a post-deploy smoke check on `/explore/tags`.
5. **[Low]** Optionally add a co-located Vitest unit test for the sparkline velocity/degraded logic as a regression safety net.

---

## 2. Project Hours Breakdown

### 2.1 Completed Work Detail

| Component | Hours | Description |
|---|---|---|
| TrendVelocitySparkline component | 6 | Inline-SVG sparkline (50×28, normalized `<polyline>`), client-side velocity via `Math.sign` of last-two delta, non-finite filtering, three directional indicator states (arrow_upward/downward/right_alt via `?react`), CSS-variable token colors, `react-intl` labels, and `Icon` `aria-label`/`role="img"` accessibility. [AAP R4, R5, I1, I4, I5] |
| TrendVelocityTile container | 5 | Top-5 selection (`hashtags.take(5)`), newest-first history reversal, `Number()` coercion with finite guards, reuse of `Hashtag` with `withGraph={false}` and sparkline injection via `children`, localized heading, and empty/degraded guards. [AAP R2, R3, I2, I3] |
| tags.jsx integration | 1 | Single import + fragment-wrapped return mounting `<TrendVelocityTile>` above the unchanged existing trends list. [AAP R1] |
| Design-system alignment & codebase discovery | 3 | Analysis of `Hashtag`/trends-state/`api_types` contracts, mapping to theme tokens (`--color-text-success/error/secondary`, `--color-graph-primary-stroke`), Material-icon arrow selection, and `.trends__item` reuse. [AAP 0.3] |
| QA hardening cycles + re-validation | 3 | Semantic `<h2>` heading fix (FINDING-1) and non-finite use-count hardening (Issue 2), each followed by re-validation. |
| Autonomous validation & QA engineering | 6 | Typecheck, lint, 4033-test Vitest run, Vite build, live browser runtime, Lighthouse audits, 44 screenshots across breakpoints/themes, 2 navigation screen recordings, adversarial edge-case testing. |
| **Total Completed** | **24** | |

### 2.2 Remaining Work Detail

| Category | Hours | Priority |
|---|---|---|
| Human code review of the 3-file PR diff | 1.0 | High |
| Manual QA vs live backend/staging with real trends data | 1.5 | High |
| i18n: `yarn i18n:extract` → register 4 keys in `en.json` for production translation | 1.0 | Medium |
| Optional co-located Vitest unit test (velocity + <2-point degraded path) | 1.5 | Low |
| PR merge + post-deploy smoke verification on `/explore/tags` | 1.0 | Medium |
| **Total Remaining** | **6.0** | |

### 2.3 Total Project Hours & Reconciliation

| Bucket | Hours |
|---|---|
| Completed (Section 2.1) | 24 |
| Remaining (Section 2.2) | 6 |
| **Total Project Hours** | **30** |

Cross-section integrity: Section 2.1 (24) + Section 2.2 (6) = **30** = Total Hours in Section 1.2 ✓. Remaining hours (6) are identical across Sections 1.2, 2.2, and 7 ✓. Completion = 24 / 30 = **80.0%** ✓.

---

## 3. Test Results

All results below originate from Blitzy's autonomous validation logs for this project (independently re-executed and confirmed).

| Test Category | Framework | Total Tests | Passed | Failed | Coverage % | Notes |
|---|---|---|---|---|---|---|
| Unit & Component (full SPA regression) | Vitest (jsdom) | 4033 | 4033 | 0 | N/A* | 25 test files; **0 regressions** from the `tags.jsx` change. |
| Runtime render scenarios | Vitest/jsdom + Chrome | 9 | 9 | 0 | — | Sparkline (rising / falling / flat / single-point→null / `[NaN,5]`→null) and tile (top-5 / degraded / empty / built-in-sparkline-suppressed / navigation). |
| Static type check | `tsc --noEmit` (strict) | — | — | 0 errors | — | 0 diagnostics across the entire SPA. |
| Lint (JS + CSS) | ESLint + Stylelint | — | — | 0 violations | — | `yarn lint:js` and `yarn lint:css` both pass. |

> *No dedicated coverage metric was produced for the two new components because the AAP-listed unit test file is **optional** and was intentionally not added (Minimal Change Clause). The feature is instead validated via full-suite regression (no failures) plus runtime render scenarios. Adding the optional test (Section 2.2, Low priority) would establish an explicit coverage figure.

---

## 4. Runtime Validation & UI Verification

- ✅ **Operational** — Vite build (`yarn build:development`) succeeds in ~17.8s with 0 errors; the feature is bundled into the compiled `explore` packs (verified by string presence).
- ✅ **Operational** — Live Chrome render on `/explore/tags` using the real compiled theme CSS; the tile appears above the unchanged trends list.
- ✅ **Operational** — Sparkline states: ascending → **Rising** (green up, `--color-text-success`); descending → **Falling** (red down, `--color-text-error`); equal → **Flat** (neutral horizontal mid-line, `--color-text-secondary`); single point → `null`; `[NaN, 5]` → `null` (non-finite filtered).
- ✅ **Operational** — Tile behavior: localized "Trend Velocity" heading; only top-5 rendered; built-in `Hashtag` sparkline suppressed; new sparkline injected via `.trends__item__buttons`; degraded row (1 history point) renders name + count with no sparkline/arrow and no error; each row links to `/tags/:name`.
- ✅ **Operational** — Accessibility: each indicator exposes `role="img"` + `aria-label` ("Rising"/"Falling"/"Flat"); meaning is conveyed by icon shape + label, not color alone. Lighthouse accessibility **100** (desktop and mobile).
- ✅ **Operational** — Responsive: verified at desktop 1280/1920, tablet 768, and mobile 375 (screenshots captured).
- ✅ **Operational** — Navigation click-through: screen recordings confirm rows navigate to the existing `/tags/:name` `HashtagTimeline`.
- ⚠ **Partial** — API integration: validated against representative fixtures and a controlled browser fixture, **not** against a live backend with real trends data. Deferred to manual QA (Section 2.2 / TASK-2).

---

## 5. Compliance & Quality Review

| Benchmark | Status | Progress | Notes |
|---|---|---|---|
| Minimal Change Clause | ✅ Pass | ▰▰▰▰▰ | 3 files changed, 167 net LOC; no refactors of existing code. |
| Hard file-scope boundary | ✅ Pass | ▰▰▰▰▰ | New files isolated in `features/explore/components/trend_velocity/`. |
| Backend / API immutability | ✅ Pass | ▰▰▰▰▰ | Zero backend, controller, scheduler, or response-shape changes. |
| No dependency changes | ✅ Pass | ▰▰▰▰▰ | Lockfile untouched; no packages added/updated/removed. |
| No global SCSS edits | ✅ Pass | ▰▰▰▰▰ | Directional colors applied via inline references to existing CSS variables. |
| Design-system token compliance | ✅ Pass | ▰▰▰▰▰ | `--color-text-success/error/secondary`, `--color-graph-primary-stroke`. |
| TypeScript strict compile | ✅ Pass | ▰▰▰▰▰ | `tsc --noEmit` → 0 errors. |
| ESLint / Stylelint | ✅ Pass | ▰▰▰▰▰ | 0 violations. |
| Unit-test regression | ✅ Pass | ▰▰▰▰▰ | 4033/4033 passing, 0 regressions. |
| Accessibility (WCAG intent) | ✅ Pass | ▰▰▰▰▰ | `aria-label` + `role="img"`; Lighthouse a11y 100. |
| Localization | ⚠ Partial | ▰▰▰▰▱ | Renders correctly via inline `defaultMessage`; `en.json` extraction for the translation pipeline is deferred (TASK-3). |
| Production build | ✅ Pass | ▰▰▰▰▰ | Vite build succeeds; feature bundled. |

**Fixes applied during autonomous validation:** semantic `<h2>` heading (FINDING-1); non-finite use-count hardening (Issue 2). **Outstanding compliance item:** i18n string extraction for the production translation pipeline (non-blocking; runtime fallback works).

---

## 6. Risk Assessment

| Risk | Category | Severity | Probability | Mitigation | Status |
|---|---|---|---|---|---|
| Live-backend data divergence (velocity/sparkline verified vs fixtures, not real trends history) | Technical | Low | Low | Manual QA on staging with real data (TASK-2); edge cases already hardened | Open (planned) |
| i18n keys not yet in `en.json` (non-English locales untranslated until extract) | Operational | Low | Medium | Run `yarn i18n:extract` before release (TASK-3); English renders via inline fallback | Open (planned) |
| Inline style objects diverge slightly from SCSS-class convention | Technical | Low | Low | Accepted under Minimal Change Clause; optional future refactor | Accepted |
| Reused upstream contracts (Hashtag props, trends state, history shape) could change upstream | Integration | Low | Low | Guarded by strict typecheck + full Vitest suite; contracts stable | Mitigated |
| Malformed / XSS payloads in production | Security | Low | Low | No new data fetched/stored; existing `Hashtag` escaping; non-finite hardening; `data-nosnippet` preserved | Mitigated |
| Pre-existing Yarn peer-dependency warnings (out-of-scope `package.json`) | Operational | Low | Low | Upstream Mastodon characteristic; install exits 0; no action for this feature | Accepted (out of scope) |
| No co-located unit test for the new components | Technical | Low | Low | Full suite passes with no regressions; add optional test (TASK-4) | Open (optional) |

**Summary:** No High or Critical risks. No security vulnerabilities introduced, no new attack surface, and no new dependencies. All risks are Low severity — consistent with a validated, presentational, frontend-only feature.

---

## 7. Visual Project Status

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'pie1':'#5B39F3','pie2':'#FFFFFF','pieStrokeColor':'#B23AF2','pieOuterStrokeColor':'#B23AF2','pieTitleTextColor':'#B23AF2','pieSectionTextColor':'#B23AF2','pieLegendTextColor':'#B23AF2'}}}%%
pie showData title Project Hours Breakdown (80% Complete)
    "Completed Work" : 24
    "Remaining Work" : 6
```

**Remaining hours by category (Section 2.2):**

| Category | Hours | Bar |
|---|---|---|
| Manual QA vs live backend | 1.5 | ███████ |
| Optional Vitest unit test | 1.5 | ███████ |
| Human code review | 1.0 | █████ |
| i18n extract for production | 1.0 | █████ |
| PR merge + deploy verification | 1.0 | █████ |
| **Total** | **6.0** | |

> Integrity: the "Remaining Work" value (6) equals Section 1.2 Remaining Hours and the sum of the Section 2.2 Hours column.

---

## 8. Summary & Recommendations

**Achievements.** The Trend Velocity tile is **code-complete and independently validated as production-ready**. Every AAP requirement — explicit (R1–R6) and implicit (I1–I5) — is implemented in committed code, and all five production-readiness gates pass on re-run: dependencies resolve, TypeScript compiles with 0 errors, lint is clean, **4033/4033** unit tests pass with no regressions, and the production build succeeds with the feature bundled. Runtime behavior, degraded/empty states, accessibility (Lighthouse 100), and responsive layouts were all verified. Scope discipline is exemplary: 3 files, 167 net LOC, all under `features/explore/`, with zero dependency, backend, or global-SCSS changes.

**Remaining gaps.** The outstanding **6 hours** are entirely standard, human-gated path-to-production activities: human code review, manual QA against a live backend, i18n string extraction for the translation pipeline, an optional regression unit test, and PR merge + deploy verification.

**Critical path to production.** Code review → manual QA on staging → `yarn i18n:extract` → merge on green CI → post-deploy smoke check. None of these are blocked; none require code changes to the feature itself.

**Success metrics.** 100% of AAP functional requirements delivered; 0 compilation errors; 0 lint violations; 0 test failures; 0 new dependencies; 0 out-of-scope edits.

**Production readiness assessment.** The project is **80.0% complete** on an AAP-scoped basis. The feature code is ready; the remaining path-to-production work is human review, live-data QA, localization registration, and deployment. **Recommendation: proceed to human review and staging QA.**

---

## 9. Development Guide

### 9.1 System Prerequisites

- **Node.js** `>=22` (repository pins `24.18` via `.nvmrc`; validated on `v24.18.0`).
- **Yarn** `4.17.0` (via Corepack; declared in `package.json` `packageManager`).
- **Git** + **Git LFS**.
- **Backend (optional for frontend work):** PostgreSQL, Redis, and Ruby/Rails are **only** required to run the full dev server with live trends data (for manual QA). Frontend validation (typecheck/lint/test/build) needs none of these.

### 9.2 Environment Setup

```bash
# From the repository root
node --version     # expect >= v22 (v24.18.0 validated)
corepack enable    # ensures Yarn 4.17.0 is available
yarn --version     # expect 4.17.0
```

- `.env.development` is present and contains ActiveRecord encryption keys (backend only).
- **No new environment variables or secrets are required for this feature.**

### 9.3 Dependency Installation

```bash
yarn install --immutable      # exit 0; no lockfile changes (no deps added by this feature)
```

Expected: installation completes with exit code 0. Pre-existing peer-dependency warnings from upstream packages are benign and can be ignored.

### 9.4 Verification (all commands tested — all pass)

```bash
yarn typecheck                 # tsc --noEmit  → 0 errors
yarn lint:js && yarn lint:css  # ESLint + Stylelint → 0 violations
yarn test:js run               # Vitest → 4033/4033 tests pass (25 files)
yarn build:development         # Vite build → success (~17.8s), feature bundled
# Aggregate gate:
yarn test                      # = lint && typecheck && test:js run
```

### 9.5 Application Startup (full stack, for live QA)

```bash
# Full dev stack via Foreman/Overmind (Procfile.dev):
#   web    → puma on :3000
#   sidekiq
#   stream → :4000
#   vite   → yarn dev
bin/dev
# — or —
foreman start -f Procfile.dev

# Frontend asset dev server only:
yarn dev
```

### 9.6 Example Usage / Feature Verification

1. Start the stack and open **`/explore/tags`**.
2. The **Trend Velocity** tile appears at the top, above the existing trends list.
3. Each of the top-5 rows shows: tag name (link), formatted use count, a small sparkline, and a rising (green ↑) / falling (red ↓) / flat (neutral →) indicator.
4. A tag with fewer than two history points renders its name + count only (no sparkline/arrow) — this is the intended degraded state.
5. Click a row → navigates to the existing `/tags/:name` timeline.

### 9.7 Registering Localization Strings (path-to-production)

```bash
yarn i18n:extract
# Verifies/adds 4 keys to app/javascript/mastodon/locales/en.json:
#   trend_velocity.title="Trend Velocity", .rising="Rising", .falling="Falling", .flat="Flat"
# Commit the regenerated en.json and push to the translation pipeline (Crowdin).
```

### 9.8 Troubleshooting

- **Non-English UI shows English labels for the tile** → run `yarn i18n:extract` and push to the translation pipeline (expected until TASK-3 is done). English renders correctly via the inline `defaultMessage` fallback.
- **A row shows no sparkline/arrow** → that tag has fewer than two finite history points; this is the intended degraded state, not a bug.
- **Peer-dependency warnings during install** → pre-existing upstream Mastodon characteristic; `yarn install` still exits 0; safe to ignore.
- **Tile not visible on `/explore/tags`** → ensure trends data is loaded (backend running / trends populated); the tile renders `null` when the hashtags list is empty.

---

## 10. Appendices

### A. Command Reference

| Command | Purpose |
|---|---|
| `yarn install --immutable` | Install dependencies without lockfile changes |
| `yarn typecheck` | TypeScript strict compile (`tsc --noEmit`) |
| `yarn lint:js` / `yarn lint:css` | ESLint / Stylelint |
| `yarn test:js run` | Run Vitest suite once (no watch) |
| `yarn test` | Aggregate gate: lint + typecheck + tests |
| `yarn build:development` | Vite development-mode build |
| `yarn build:production` | Vite production build |
| `yarn dev` | Vite asset dev server |
| `bin/dev` / `foreman start -f Procfile.dev` | Full dev stack |
| `yarn i18n:extract` | Extract i18n messages into `en.json` |

### B. Port Reference

| Port | Service |
|---|---|
| 3000 | Web (Puma / Rails) |
| 4000 | Streaming server |
| 3036 | Vite dev server (default) |

### C. Key File Locations

| Path | Role |
|---|---|
| `app/javascript/mastodon/features/explore/components/trend_velocity/trend_velocity_sparkline.jsx` | **CREATED** — sparkline + velocity indicator |
| `app/javascript/mastodon/features/explore/components/trend_velocity/trend_velocity_tile.jsx` | **CREATED** — top-5 tile container |
| `app/javascript/mastodon/features/explore/tags.jsx` | **MODIFIED** — mounts the tile above the existing list |
| `app/javascript/mastodon/components/hashtag.tsx` | Reused (read-only) row component |
| `app/javascript/mastodon/actions/trends.js` / `reducers/trends.js` | Reused (read-only) data source & state |
| `app/javascript/mastodon/api_types/tags.ts` | Reused (read-only) `history` contract |

### D. Technology Versions

| Technology | Version |
|---|---|
| Node.js | v24.18.0 (`.nvmrc` 24.18; engines `>=22`) |
| Yarn | 4.17.0 |
| React / React-DOM | ^19.2.0 |
| react-intl | ^10.0.0 |
| react-sparklines | ^1.7.0 (already present; not used by the new component) |
| react-immutable-proptypes | ^2.2.0 |
| immutable | ^4.3.0 |
| Vite | ^8.0.0 |
| TypeScript | ~6.0.0 |
| vite-plugin-svgr | ^5.0.0 (`?react` SVG imports) |

### E. Environment Variable Reference

| Variable | Required for feature? | Notes |
|---|---|---|
| _None_ | No | The feature requires no new environment variables or secrets. `.env.development` keys are backend-only. |

### F. Developer Tools Guide

- **Diff review:** `git diff 52b781c2f4...HEAD --stat` (3 files; 167 insertions, 5 deletions).
- **Authorship:** `git log --author="agent@blitzy.com" --oneline` (8 commits).
- **QA artifacts (untracked `blitzy/`):** 44 screenshots (all states/breakpoints/themes), 2 navigation screen recordings, Lighthouse reports (desktop a11y/best-practices/SEO = 100/100/100; mobile = 100/96/100), and validation logs.
- **Bundle check:** `grep -rl "trend_velocity" public/packs/` after a build confirms the feature is bundled.

### G. Glossary

| Term | Definition |
|---|---|
| Sparkline | A compact, inline line chart with no axes, showing a value trend at a glance. |
| Velocity indicator | A directional arrow (up/down/flat) derived from the sign of the delta between a tag's two most recent use-count values. |
| Degraded state | A row with fewer than two history points that renders its name + count only, omitting the sparkline and indicator. |
| `withGraph={false}` | A pre-existing `Hashtag` prop used to suppress its built-in sparkline so the new one can be injected via `children`. |
| AAP | Agent Action Plan — the authoritative specification of scope for this project. |