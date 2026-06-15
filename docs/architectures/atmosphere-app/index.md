# atmosphere-app — Arquitectura

> Auto-generado desde [manifest.yaml](./manifest.yaml). No editar a mano.

**Tipo:** frontend | **Lenguaje:** flutter

## Específico del servicio
- [Overview](./overview.md)
- [Manifest](./manifest.yaml)

## Convenciones activas

- **[Convenciones generales](../../../.claude/conventions/flutter/_base.md)** — convenciones base de cualquier app Flutter (siempre activas).
- **[Estado (Riverpod + StateNotifier)](../../../.claude/conventions/flutter/state-management.md)** — estado con providers de Riverpod y StateNotifier, + DI.
- **[Networking (http + repository)](./conventions/networking.md)** — cliente `http` envuelto en ApiClient, repository y mapeo de errores (custom).
- **[Internacionalización (intl)](./conventions/i18n.md)** — localización (ARB + gen-l10n) y formato numérico locale-aware con intl (custom).
- **[Modelos y serialización (freezed + json_serializable)](../../../.claude/conventions/flutter/models-serialization.md)** — modelos inmutables con copyWith, equality y JSON.
- **[Navegación (go_router)](../../../.claude/conventions/flutter/navigation.md)** — routing declarativo por URL, rutas tipadas y guards.
- **[Theming y design system](../../../.claude/conventions/flutter/theming.md)** — tokens de diseño (color, tipografía, spacing) en `ThemeData`.
- **[Testing (flutter_test + mocktail)](../../../.claude/conventions/flutter/testing.md)** — tests unit, widget y de providers con mocktail y ProviderScope.
- **[Configuración de entorno (flutter_dotenv)](../../../.claude/conventions/flutter/env-config.md)** — env/config tipado al arranque, por flavor.
- **[Manejo de errores](../../../.claude/conventions/flutter/error-handling.md)** — modelo de excepciones de dominio, mapeo desde transporte y superficies de error en UI (auto-incluida).

---

**Total:** 10 convenciones activas.
