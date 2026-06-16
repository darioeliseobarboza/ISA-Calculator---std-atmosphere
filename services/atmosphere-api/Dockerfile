# syntax=docker/dockerfile:1

# ---- builder ----------------------------------------------------------------
# Pinned to the toolchain declared in go.mod (Go 1.26.4). No :latest.
FROM golang:1.26.4-alpine3.24 AS builder

WORKDIR /src

# Cache the module graph: copy manifests and download before the source so a
# code-only change does not re-download dependencies.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Static, stripped binary: no CGO, trimmed paths, no symbol table / DWARF.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath -ldflags="-s -w" \
    -o /out/app ./cmd/atmosphere-api

# ---- runtime ----------------------------------------------------------------
# Distroless static, non-root: only the binary ships, no shell, no package mgr.
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

WORKDIR /app
COPY --from=builder /out/app /app/app

USER nonroot:nonroot

# Matches the default HTTP_ADDR=:8080.
EXPOSE 8080

ENTRYPOINT ["/app/app"]
