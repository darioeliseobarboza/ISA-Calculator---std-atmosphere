---
created: 2026-06-12
last_updated: 2026-06-12
status: "Análisis técnico cerrado"
analisis_funcional: docs/discovery/analisis-funcional.md
analisis_dominio: docs/discovery/analisis-dominio.md
alcance: "Tecnologías, servicios, comunicación y flujos clave. Se difieren CI/CD, testing, observabilidad, estructura de proyecto y hosting."
---

# Análisis Técnico — Calculadora ISA (Atmósfera Estándar)

> **Alcance de este documento:** tecnologías, servicios, comunicación y flujos clave
> ÚNICAMENTE. Se difieren a una iteración posterior: CI/CD, testing, observabilidad,
> estructura de proyecto y hosting.

---

## Mapa de Servicios

```
┌──────────────────────────────┐      HTTP/REST (JSON, síncrono)     ┌──────────────────────────────────┐
│   atmosphere-app (Flutter)   │  ── POST /v1/calculate ───────────▶ │   atmosphere-api (Go, stateless)  │
│   Windows · Linux · Web      │                                     │   motor ISA: analítico +           │
│   entrada · unidades · render│  ◀── 200 {resultados, comparacion} ─│   interpolación + comparación      │
└──────────────────────────────┘                                     └──────────────────────────────────┘
        Contexto: Presentación                                            Contexto: Cálculo Atmosférico
                                                                          (sin DB · sin bus · sin storage)
```

### Servicios

| # | Servicio | Responsabilidad |
|---|---|---|
| S1 | **atmosphere-api** | Ejecutar ambos métodos (analítico + interpolación), generar la tabla, computar comparación/error y convertir al sistema de unidades pedido. Stateless. |
| S2 | **atmosphere-app** | Entrada del usuario, selección de sistema de unidades, formato/precisión, render de la comparación. No calcula. |

### Infraestructura Compartida

| Componente | Rol |
|---|---|
| Base de datos | Ninguna (servicio stateless) |
| Bus de mensajería | Ninguno |
| Storage / CDN | Ninguno |
| Cache | Ninguno (cálculo instantáneo; la tabla se genera en memoria por petición) |

### Servicios eliminados / fusionados

- **Base de datos / persistencia** — el dominio es stateless y no hay historial en v1.
- **Servicio separado de "generación de tabla" o "comparación"** — es lógica en memoria dentro de `atmosphere-api`; separarla sería sobre-ingeniería.
- **Bus de mensajería (NATS/Kafka/colas)** — comunicación 100% request/response síncrona.
- **Gateway / servicio de auth** — sin cuentas ni autenticación en v1.

---

## Tecnologías por Servicio

### S1 — atmosphere-api (Go)

| Pieza | Tecnología | Razón |
|---|---|---|
| Lenguaje | **Go 1.26.4** | Decisión del usuario; binario único, ideal para un servicio stateless liviano |
| Router / HTTP | **stdlib `net/http`** | Router del estándar (1.22+) con patrones método+path; cero dependencias, suficiente para 1–2 endpoints |
| Serialización | `encoding/json` (stdlib) | JSON request/response; cero dependencias |
| Cálculo numérico | `math` (stdlib), `float64` | Constantes exactas ISA 1976; ρ₀/a₀/μ₀/n derivados en runtime; sin redondeo interno (solo al mostrar) |
| Forma de la API | **POST con body JSON** (`POST /v1/calculate`) | Convencional para "calcular"; cómodo si la entrada crece |
| Validación | stdlib (parseo + chequeo de rango) | Pocas reglas (0–36.089 ft, paso>0); no amerita librería |
| Conversión de unidades | propia, en la API | Decisión de dominio: la API entrega ya convertido al sistema pedido |
| Config | flags / env (puerto, orígenes CORS) | Minimal, sin secretos |
| Persistencia | **ninguna** | Servicio stateless |
| CORS | habilitado, orígenes configurables | Necesario para el target Web (cross-origin); el desktop no lo usa |

### S2 — atmosphere-app (Flutter)

| Pieza | Tecnología | Razón |
|---|---|---|
| Framework | **Flutter** (Dart) | Decisión del usuario; un solo código para Windows/Linux/Web |
| Targets | `windows`, `linux`, `web` | Requerimiento del producto |
| Gestión de estado | **Riverpod** | Manejo limpio de estados async (`AsyncValue`: loading/data/error) para la llamada a la API; testeable y escala bien |
| Cliente HTTP | `http` (oficial) | Una sola llamada; simple y mantenido |
| Formato numérico / i18n | `intl` | Formateo localizado (es), cifras significativas y notación científica |
| Empaquetado Web | build web servido por contenedor estático (p. ej. nginx) → **Dockerfile** | Requerimiento del usuario |
| Build escritorio | `flutter build windows` / `linux` + documentación | Requerimiento del usuario |
| Sección de fórmulas | contenido **estático** en la app | Referencia de conversión SI↔imperial (y m↔ft) por magnitud; sin endpoint |

### Convenciones / componentes compartidos

| Pieza | Definición |
|---|---|
| Contrato JSON | Identificadores en **inglés**: tipos `PascalCase`, campos/enums `camelCase` (`geopotentialAltitude`, `dynamicViscosity`, `relativeErrorPct`, …) |
| Unidades de salida | Cada magnitud absoluta se devuelve en **ambos** sistemas: objeto `{si, imperial}`; los relativos son adimensionales (valor único) |
| Enum `altitudeUnit` | `m` \| `ft` (unidad de la entrada de altitud/paso; se normaliza a ft) |
| Enum `method` | `analytical` \| `interpolation` |
| Formato de error | `{ "error": { "code": string, "message": string } }` con códigos `outOfRange` \| `invalidInput` \| `invalidStep` |

---

## Comunicación entre Servicios

### Conexiones

| De → A | Protocolo | Dirección | Naturaleza |
|---|---|---|---|
| atmosphere-app → atmosphere-api | HTTP/REST (JSON) | unidireccional | Síncrona request/response (todo el cálculo) |

### Patrones

1. **Síncrono request/response (HTTP)** — una única llamada por cálculo; la API devuelve ambos métodos + comparación + metadata de la tabla en una sola respuesta.
2. Sin async, sin fan-out, sin colas, sin bus — el producto no tiene procesos en segundo plano.

### Subjects de mensajería

No aplica (sin bus de mensajería).

---

## Tokens y Autenticación

### Filosofía

Sin identidad de usuario, sin sesión, sin tokens. Es una herramienta personal y anónima;
el cálculo no maneja datos sensibles. La única consideración de seguridad de v1 es
**CORS** en `atmosphere-api` (orígenes permitidos configurables) para habilitar el
target Web. Un mecanismo de auth/API key se podría sumar más adelante si la API se
expone públicamente, pero queda fuera de v1.

---

## Flujos Clave

> Producto de una sola jornada. Los nombres de campos son el **contrato autoritativo**
> (se transcriben verbatim a la spec OpenAPI y a `docs/flows/` aguas abajo).

### Cálculo y comparación

**Endpoint:** `POST /v1/calculate`

**Request:**
```json
{
  "geopotentialAltitude": 16404,
  "altitudeUnit": "ft",
  "tableStep": 1000
}
```
- `geopotentialAltitude` (number, req): en la unidad de `altitudeUnit`. La API la **normaliza a ft** y valida `0–36.089 ft` (≈ `0–11.000 m`).
- `altitudeUnit` (enum, opt, default `ft`): `m` \| `ft`. Unidad de la **entrada** (altitud y paso).
- `tableStep` (number, opt, default `1000` ft): en la unidad de `altitudeUnit`; `>0` y `≤ 36.089 ft` equivalente.
- La respuesta trae **SI e imperial** simultáneamente y **eco-devuelve `geopotentialAltitude` en m y ft** (ambas), sea cual sea la unidad de entrada.

**Response 200:**
```json
{
  "input": { "geopotentialAltitude": { "m": 5000.0, "ft": 16404 }, "altitudeUnit": "ft", "tableStep": 1000 },
  "results": {
    "analytical": {
      "method": "analytical",
      "temperature":        { "si": 255.69,   "imperial": 460.24 },
      "pressure":           { "si": 54019.9,  "imperial": 1128.3 },
      "density":            { "si": 0.7361,   "imperial": 0.001428 },
      "dynamicViscosity":   { "si": 1.628e-5, "imperial": 3.40e-7 },
      "kinematicViscosity": { "si": 2.211e-5, "imperial": 2.380e-4 },
      "speedOfSound":       { "si": 320.55,   "imperial": 1051.7 },
      "theta": 0.8874, "delta": 0.5331, "sigma": 0.6009, "speedOfSoundRatio": 0.9420, "viscosityRatio": 0.9098
    },
    "interpolation": { "method": "interpolation", "...": "misma estructura: T,P,ρ,μ,ν,a en {si,imperial} + relativos únicos" }
  },
  "comparison": [
    { "magnitude": "temperature", "analyticalValue": { "si": 255.69, "imperial": 460.24 }, "interpolationValue": { "si": 255.69, "imperial": 460.24 }, "absoluteDifference": { "si": 0.0, "imperial": 0.0 }, "relativeErrorPct": 0.0 },
    { "magnitude": "pressure",    "analyticalValue": { "si": 54019.9, "imperial": 1128.3 }, "interpolationValue": { "si": 54040.1, "imperial": 1128.7 }, "absoluteDifference": { "si": 20.2, "imperial": 0.42 }, "relativeErrorPct": 0.037 }
    // … una fila por magnitud (11). Absolutas: {si, imperial}; relativos: valor único; relativeErrorPct: adimensional
  ],
  "table": { "step": 1000, "minAltitude": 0, "maxAltitude": 36089, "nodeCount": 38 }
}
```

**Response 400:**
```json
{ "error": { "code": "outOfRange", "message": "geopotentialAltitude out of range (0–36089 ft ≈ 0–11000 m)" } }
```

**Secuencia:**
```
Usuario        atmosphere-app                          atmosphere-api
  │  ingresa h, paso, unidades
  │ ───────────▶ │ valida formato (numérico)
  │              │ ── POST /v1/calculate {…} ─────────────▶ │ normaliza a ft + valida 0–36.089 ft
  │              │                                         │   (inválido → 400 error.code)
  │              │                                         │ analytical + genera tabla + interpola
  │              │                                         │ + comparación (Δ, error%) + salida SI e imperial
  │              │ ◀── 200 {results, comparison, table} ──
  │ ◀── render comparación (intl) ── │
```

*(Los valores numéricos del ejemplo son ilustrativos.)*

---

## Validación de Cobertura

**Cobertura: 19/19 requerimientos funcionales de v1 (100%).**

| Categoría | Requerimiento | Cubierto por |
|---|---|---|
| Cálculo | Cálculo analítico de punto único (FG-1) | atmosphere-api (motor analítico, fórmulas ISA) |
| Cálculo | Cálculo por interpolación (FG-2) | atmosphere-api (genera tabla por fórmula + interpola) |
| Cálculo | Comparación lado a lado + diferencia/error (FG-3) | atmosphere-api (computa) + atmosphere-app (render) |
| Magnitudes | Temperatura, presión, densidad (T, P, ρ) | atmosphere-api |
| Magnitudes | Viscosidad dinámica μ (Sutherland) | atmosphere-api |
| Magnitudes | Viscosidad cinemática ν = μ/ρ | atmosphere-api |
| Magnitudes | Velocidad del sonido a = √(γRT) | atmosphere-api |
| Magnitudes | Relativos θ, δ, σ, a/a₀, μ/μ₀ | atmosphere-api |
| Unidades | SI + imperial simultáneos | atmosphere-api (devuelve ambos) + atmosphere-app (muestra ambos) |
| Entrada | Altitud geopotencial (en m o ft, `altitudeUnit`) | atmosphere-app (input + selector m/ft) + atmosphere-api (normaliza a ft) |
| Entrada | Validación de rango 0–36.089 ft | atmosphere-api (autoritativo) + atmosphere-app (validación previa) |
| Entrada | Paso de tabla configurable (default 1.000 ft) | atmosphere-api (`tableStep`) + atmosphere-app (control) |
| Salida | Altitud eco-devuelta en m y ft | atmosphere-api (eco-convierte la altitud de entrada) |
| Presentación | Sección de fórmulas de conversión (referencia) | atmosphere-app (contenido **estático**; sin endpoint) |
| Presentación | Formato y precisión numérica | atmosphere-app (`intl`) |
| Presentación | UI en español | atmosphere-app |
| Plataforma | Multiplataforma Windows / Linux / Web | atmosphere-app (targets Flutter) + Dockerfile (web) |
| Plataforma | Cálculo remoto vía API (cliente-servidor) | atmosphere-api + HTTP/REST |
| Plataforma | Stateless / sin persistencia | atmosphere-api (sin DB) |

### Diferidos a nivel producto (fuera de v1, ya decidido en el análisis funcional)

Nombrados para que no queden como omisión silenciosa — no cuentan en el denominador de v1:

| Requerimiento diferido | Razón |
|---|---|
| Capas sobre 11 km (tropopausa, estratósfera, …) | Fuera de v1; `AtmosphericLayer` deja lugar a sumarlas |
| Altitud geométrica + conversión geopotencial↔geométrica | Fuera de v1 |
| Atmósfera no estándar (desviación ISA / offset de T) | Fuera de v1 |
| Modo batch / generación de tabla por rango | Fuera de v1 (solo punto único) |
| Exportar / historial de cálculos | Fuera de v1 (mantiene el servicio stateless) |
| Relativo ν/ν₀ | Posible agregado futuro (v1 incluye μ/μ₀) |

---

## Decisiones Operativas Fuera de Alcance

Diferidas a una iteración posterior (no se deciden en este documento):

- **Estructura del proyecto** (monorepo / multirepo, layout de carpetas).
- **CI/CD** y ambientes.
- **Testing** (unit/integration/e2e) — aunque el criterio de éxito funcional es validar el método analítico contra una tabla ISA publicada.
- **Observabilidad** (logs, métricas, traces).
- **Hosting / despliegue** (dónde corre la API, cómo se publica el web, distribución de los binarios de escritorio).
- **Secrets / gestión de configuración** más allá de flags/env.

---

## Resumen de Decisiones Técnicas

| # | Tema | Decisión |
|---|---|---|
| Arq-1 | Servicios | 2 servicios: `atmosphere-api` (Go, stateless) + `atmosphere-app` (Flutter Win/Linux/Web). Sin DB, sin bus, sin storage |
| Arq-2 | Stack API | Go 1.26.4 + stdlib `net/http` + `encoding/json` + `math`/`float64`; validación stdlib |
| Arq-3 | Stack frontend | Flutter (Dart) + Riverpod + `http` + `intl`; targets windows/linux/web |
| Arq-4 | Comunicación | HTTP/REST síncrono; un único `POST /v1/calculate` devuelve ambos métodos + comparación + tabla |
| Arq-5 | Unidades | Cálculo interno en **ft**; la consulta lleva `altitudeUnit` (entrada). La respuesta trae cada magnitud absoluta en SI **e** imperial a la vez (sin toggle) |
| Arq-6 | Auth | Ninguna en v1; solo CORS configurable para el target Web |
| Arq-7 | Empaquetado | Web vía Dockerfile (contenedor estático); escritorio vía `flutter build` + documentación |
| Arq-9 | Fórmulas / altitud | Sección de fórmulas de conversión **estática** en el frontend (sin endpoint); la API eco-devuelve la altitud en m y ft |
| Arq-8 | Versionado API | Prefijo `/v1/` en la ruta |
