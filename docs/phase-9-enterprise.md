# Phase 9 — Enterprise Layer

## Purpose
RBAC, organizations/teams, API keys, audit logs with billing hooks, and
an admin monitoring dashboard — new `enterprise/` package, SQLite-backed
(storage/enterprise.db), stdlib-only. Existing auth flow untouched.

## Components
- rbac: admin/developer/viewer roles with permission sets; require() raises
- orgs: organizations → teams → members (email+role); role lookup
- api_keys: raw shown ONCE, only sha256 stored; verify/list(masked)/revoke
- audit: every important action recorded (actor/action/resource/detail/cost);
  usage_summary() = billing hook (per-actor cost + totals)
- monitor: one dashboard payload — Phase 1 metrics + Phase 4 agent health +
  Phase 8 provider stats + recent audit; every source optional (degrades)

## New endpoints (JWT, /api/v1/admin/*)
roles · orgs CRUD · teams · members · apikeys (create/list/revoke) ·
audit · usage · dashboard

## Security notes
Raw API keys never stored or logged (audit stores name only). Current
deployment has a single admin user; RBAC is enforced-ready for when
multi-user auth lands (roles stored per org member).

## Testing
tests/test_enterprise_phase9.py — 5 groups, all passing (revoked-key
rejection, masked listing, billing math, dashboard degradation).

## Limitations / future
JWT does not yet carry per-org roles (single-admin today); password
hashing for the admin login is the top follow-up.
