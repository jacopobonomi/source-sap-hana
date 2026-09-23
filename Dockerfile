# syntax=docker/dockerfile:1
FROM python:3.11-slim AS build
COPY --from=ghcr.io/astral-sh/uv:0.9 /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
WORKDIR /airbyte/integration_code
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --no-dev --no-install-project
COPY src ./src
RUN uv sync --frozen --no-dev --no-editable

FROM python:3.11-slim
WORKDIR /airbyte/integration_code
COPY --from=build /airbyte/integration_code/.venv ./.venv
ENV PATH="/airbyte/integration_code/.venv/bin:$PATH" \
    AIRBYTE_ENTRYPOINT="source-sap-hana"
RUN useradd --uid 1000 --create-home airbyte
USER airbyte
ENTRYPOINT ["source-sap-hana"]

LABEL io.airbyte.name=source-sap-hana \
      io.airbyte.version=0.4.2
