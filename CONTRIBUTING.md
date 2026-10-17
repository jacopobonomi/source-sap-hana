# Contributing

## Setup

```bash
uv sync
uv run pytest
uv run ruff check . && uv run ruff format --check .
```

## Test layers

| Layer | Where | Needs HANA? |
|---|---|---|
| Unit tests | `unit_tests/test_*.py` | no |
| Airbyte CDK standard tests | `unit_tests/test_standard_suite.py` + `acceptance-test-config.yml` | no |
| SSH tunnel tests | `unit_tests/test_ssh_tunnel.py` (in-process paramiko SSH server + echo server) | no |
| Integration tests | `integration_tests/` (`-m integration`) | yes, `secrets/config.json` (tunnel test also needs Docker) |
| Docker image tests | CDK `image_tests` marker (`-m image_tests`) | no |

### The fake HANA

`unit_tests/conftest.py` replaces `hdbcli.dbapi.connect` with a SQLite database that attaches
in-memory databases named `SYS` and `SAPHANADB`. The connector's real SQL runs unchanged against it:
`SYS.TABLES`, quoted `"SAPHANADB"."ACDOCA"`, `NULLS FIRST`, `LIMIT` and `?` parameters.
To simulate HANA dropping the connection after N fetched rows, set `hana.fail_after_rows = [N, ...]`
(one entry per data query). The error raised is a real `hdbcli.dbapi.OperationalError(-10807, ...)`.

### Real HANA

Copy `integration_tests/sample_config.json` to `secrets/config.json` and fill in the credentials.
The integration tests only read a handful of rows per table.

## Pull requests

- Add a unit test for every behaviour change, and a fake-HANA failure scenario for anything touching retries or state.
- Update `CHANGELOG.md` and bump the version in `pyproject.toml`, `metadata.yaml` and `Dockerfile`.

## Releasing

1. Bump the version in `pyproject.toml`, `metadata.yaml` and `Dockerfile`, and add a `CHANGELOG.md` entry.
2. Merge to `main`, then tag and push: `git tag v<version> && git push origin v<version>`.
3. The `Release image` workflow checks that the tag matches `pyproject.toml`, builds `linux/amd64` + `linux/arm64`,
   pushes `ghcr.io/jacopobonomi/source-sap-hana:<version>` and `:latest`, and smoke-tests `spec` on both architectures.
