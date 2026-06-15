# atmosphere-api — Arquitectura

> Auto-generado desde [manifest.yaml](./manifest.yaml). No editar a mano.

**Tipo:** api | **Lenguaje:** golang

## Específico del servicio
- [Overview](./overview.md)
- [Manifest](./manifest.yaml)

## Convenciones activas

- **[Convenciones generales](../../../.claude/conventions/golang/_base.md)** — convenciones base de cualquier servicio Go (siempre activas).
- **[Servidor HTTP (stdlib net/http)](./conventions/http-server.md)** — servidor HTTP, routing y middleware con la stdlib (custom).
- **[Logging estructurado (slogx)](./conventions/logging.md)** — logging estructurado, consola + archivos JSON por nivel (custom).
- **[Configuración de entorno (dotenv)](./conventions/config.md)** — carga de env vars en un Config tipado, validado al arranque (custom).
- **[Dockerfile (Go)](../../../.claude/conventions/golang/dockerfile.md)** — build multi-stage, imagen chica, non-root, estática.
- **[Testing (testify + table-driven)](../../../.claude/conventions/golang/testing.md)** — tests unitarios e integración, table-driven, testcontainers.
- **[Manejo de errores](../../../.claude/conventions/golang/error-handling.md)** — modelado/wrapping de errores y forma canónica en el boundary (auto-incluida).

---

**Total:** 7 convenciones activas.
