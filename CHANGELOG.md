# Changelog

## 0.4.2 — 2026-09-23

- **SSH tunnel host key verification**: new optional `tunnel_host_key_fingerprint` (SHA256, as printed by `ssh-keygen -lf`).
  When set, any other bastion key is rejected. When empty, the key is trusted on first use and its fingerprint is logged.
- Code-scanning cleanups: no `BaseException` handling in worker threads, and no silent `except: pass`.

## 0.4.1 — 2026-09-23

- Fix: `ESTIMATE` traces now include `byte_estimate` (from `SYS.M_TABLES.TABLE_SIZE`). The Airbyte platform
  failed the sync with `getByteEstimate(...) must not be null` without it. Found by the first run on a real
  Airbyte OSS instance (abctl, arm64).

## 0.4.0 — 2026-09-23

- **Concurrent stream reads** (`max_concurrent_streams`, default 1): each stream runs on its own worker and HANA
  connection, and messages are interleaved through a bounded buffer. On 7 real tables with 3 workers the sync
  went from 23.5 s to 9.2 s with identical record counts.
- **Row estimates**: unfiltered full refreshes emit an `ESTIMATE` trace from `SYS.M_TABLES`, so the Airbyte UI can show progress.
- **Check-time validation** of `stream_settings`: every condition runs with `LIMIT 0`, so syntax errors,
  unknown columns and unknown tables are reported by `check`.
- User documentation page in Airbyte's docs format (`docs/sap-hana-oss.md`).

## 0.3.0 — 2026-09-23

- **SSH tunnel** with Airbyte's standard `tunnel_method` (key or password auth), built on paramiko. The transport
  reconnects by itself when the bastion drops the session, and TLS keeps validating the real HANA host name
  (`sslHostNameInCertificate`).
- **Per-stream settings** (`stream_settings`) replace `stream_filters`: `condition`, a default `cursor_field`
  (exposed as `default_cursor_field`), and a `primary_key` override for tables without a PK constraint (e.g. `ACDOCA`).
- Incremental requested without a cursor (as PyAirbyte does) falls back to full refresh instead of failing.
- Integration tests: page-by-page reconciliation with `COUNT(*)`, and the SSH tunnel through a throwaway Docker bastion.

## 0.2.0 — 2026-09-23

- **Resumable full refresh**: tables with a primary key are read in pages ordered by the key
  (`resumable_full_refresh`, `full_refresh_page_size`). A dropped connection resumes after the last
  emitted row, with no duplicates, and the Airbyte platform can resume a failed attempt from the last page.
- **Per-stream filters** (`stream_filters`): SQL conditions applied in every sync mode.
- **Protocol compression** (`compress`, on by default): full refresh of 941k `MAKT` rows over VPN went from 86 s to 23 s.
- `discover` now fails with a config error when a configured schema does not exist.
- Airbyte CDK standard test suite (spec/check/discover/read contract) on a fake HANA.
- Integration test that checks every discovered stream's values against its JSON schema on a real HANA.

## 0.1.0 — 2026-09-23

- First version: spec, check, discover (tables/views, primary keys, `LIKE` filters),
  streamed full refresh, cursor-based incremental with safe checkpoints,
  reconnect on transient HANA errors, NUL stripping, TLS/MDC support, Docker image.
