---
created: 2026-06-12
last_updated: 2026-06-12
status: "Análisis funcional cerrado"
documento_base: "ninguno (desde cero)"
---

# Análisis Funcional — Calculadora ISA (Atmósfera Estándar)

## Contexto y Alcance

### Producto

Calculadora de **Atmósfera Estándar Internacional (ISA)** multiplataforma (Windows,
Linux y Web). Dada una **altitud geopotencial**, calcula los parámetros atmosféricos
básicos —temperatura, presión, densidad y viscosidad— por **dos métodos
independientes** (analítico por fórmulas y por interpolación de tabla) y los muestra
**lado a lado con su diferencia/error**. El **cálculo lo realiza una API** y el
**frontend solo presenta** los resultados obtenidos por petición. Es una herramienta
personal de ingeniería, mono-usuario.

### Objetivo Estratégico

Herramienta utilitaria de uso personal. **No hay objetivo de negocio, monetización ni
distribución a terceros.** El valor está en obtener los parámetros rápido y en poder
**comparar los dos métodos de cálculo** para dimensionar el error de interpolación.

### Principios Rectores

- **Cálculo en el servidor, cliente liviano** — el cálculo lo realiza una API; el
  frontend solo muestra los resultados obtenidos por petición. Requiere conectividad con
  la API.
- **Comparación como feature central** — el producto existe para confrontar el método
  analítico contra el de interpolación; mostrar la diferencia/error no es accesorio.
- **Corrección numérica primero** — los resultados deben coincidir con la tabla ISA de
  referencia dentro de una tolerancia; es el criterio de éxito.
- **Decisión-completa y acotada** — v1 cubre solo la tropósfera (una capa), sin
  features especulativas.

### Alcance v1

| Dentro del alcance v1 | Fuera del alcance v1 |
|---|---|
| Cálculo de **punto único** (altitud geopotencial → magnitudes) | Capas sobre 11 km (tropopausa, estratósfera, etc.) |
| Método **analítico** (fórmulas ISA cerradas) | Altitud **geométrica** y conversión geopotencial↔geométrica |
| Método por **interpolación** (tabla generada por fórmula) | Atmósfera **no estándar** (desviación ISA, offsets de T) |
| **Comparación lado a lado** + diferencia/error | Cuentas de usuario / autenticación |
| Unidades **SI + imperial** (simultáneo) | **Exportar / historial** de cálculos |
| Salidas T, P, ρ, μ, ν, a + relativos θ, δ, σ, a/a₀, μ/μ₀ | Generación de **tabla/rango** (modo batch) |
| **API de cálculo** + **frontend** multiplataforma (Win/Linux/Web) | **Multi-idioma** (solo español) |
| Altitud eco-devuelta en m y ft + sección de **fórmulas de conversión** (referencia) | — |

### Restricciones

**Técnicas:**
- El **cálculo se realiza en una API** (backend); el **frontend** solo presenta los
  resultados obtenidos por petición a esa API.
- El **frontend** debe poder distribuirse para **Windows, Linux y Web**.
- **Requiere conectividad** con la API para calcular (no es offline).

**De negocio/legales:** ninguna relevante (uso personal, sin datos de usuario ni PII).

> El **stack y la arquitectura concreta** (lenguaje de la API, framework del frontend,
> protocolo de comunicación, empaquetado web y build de escritorio) se definen en
> `/product-discovery-technical`, no acá.

---

## Mapa Funcional

> **Draft.** `/product-initialize` lo formaliza en feature groups reales (FG-1 =
> esqueleto end-to-end).

```
Calculadora ISA (Atmósfera Estándar)
├── [FG-1] Cálculo analítico de punto único   (esqueleto end-to-end)
├── [FG-2] Cálculo por interpolación (tabla generada por fórmula)
├── [FG-3] Comparación lado a lado + diferencia/error
└── Transversales
    ├── Sistema de unidades (SI e imperial, simultáneo)
    ├── Validación de entrada y rango (0–36.089 ft geopotencial)
    ├── Formato y precisión numérica
    ├── Fórmulas de conversión (referencia)
    ├── Arquitectura cliente-servidor (API de cálculo + frontend Win/Linux/Web)
    └── UI en español
```

**Set de magnitudes (idéntico para ambos métodos):**

| Categoría | Magnitudes |
|---|---|
| Primarias | T (temperatura), P (presión), ρ (densidad) |
| Viscosidad | μ dinámica, ν cinemática = μ/ρ |
| Derivada | a velocidad del sonido = √(γ·R·T), γ = 1.4 |
| Relativas (adimensionales) | θ = T/T₀, δ = P/P₀, σ = ρ/ρ₀, a/a₀ = √θ, μ/μ₀ |

---

## FG-1 — Cálculo analítico de punto único

### Objetivo

Esqueleto end-to-end: el usuario ingresa una altitud geopotencial y obtiene el set
completo de magnitudes calculadas con las **fórmulas cerradas de la ISA** (tropósfera).

### Configuraciones

| Configuración | Default | Alternativas |
|---|---|---|
| Unidad de altitud de entrada | ft | m (se normaliza a ft) |
| Unidades de salida | SI e imperial (a la vez) | — (ver Transversales) |
| Magnitudes mostradas | Todas | — (v1 muestra el set completo) |

### Flujo

1. El usuario ingresa una **altitud geopotencial** `h`, eligiendo su **unidad de altitud** (`m` o `ft`), independiente del sistema de unidades de salida.
2. Se normaliza `h` a **ft** y se valida que esté en rango `[0, 36.089] ft` (ver Edge cases).
3. Se calcula con las fórmulas ISA de tropósfera (ver Reglas).
4. Se muestran las magnitudes absolutas en **SI e imperial** (a la vez), las relativas (adimensionales) y la **altitud de entrada en m y ft**.

### Reglas (fórmulas ISA — tropósfera, capa única 0–11 km)

Constantes (estándar **ISA 1976 / ICAO**, doble precisión): `R* = 8.31432 J/(mol·K)`,
`M₀ = 0.0289644 kg/mol`, `R = R*/M₀ ≈ 287.05287 J/(kg·K)`, `T₀ = 288.15 K`, `P₀ = 101325 Pa`,
`L = −0.0065 K/m = −0.0019812 K/ft`, `g₀ = 9.80665 m/s²`, `γ = 1.4`; Sutherland `β = 1.458e-6`, `S = 110.4 K`.
Derivadas en runtime (float64, sin redondear): `ρ₀ = P₀/(R·T₀) ≈ 1.2250 kg/m³`,
`a₀ = √(γ·R·T₀) ≈ 340.294 m/s`, `μ₀ ≈ 1.78937e-5 Pa·s`, exponente `n = g₀/(R·|L|) ≈ 5.25588`.
La altitud `h` se maneja en **ft** (canónica). El redondeo es solo de presentación.

- **Temperatura:** `T = T₀ + L·h` (lineal con la altitud; `h` en ft, `L` en K/ft).
- **Presión:** `P = P₀ · (T/T₀)^n`.
- **Densidad:** `ρ = ρ₀ · (T/T₀)^(n−1)` (equivale a `ρ = P/(R·T)`).
- **Velocidad del sonido:** `a = √(γ·R·T)`.
- **Viscosidad dinámica (Sutherland):** `μ = β·T^(3/2) / (T + S)`, con
  `β = 1.458e-6 kg/(m·s·√K)` y `S = 110.4 K`.
- **Viscosidad cinemática:** `ν = μ / ρ`.
- **Relativos:** `θ = T/T₀`, `δ = P/P₀`, `σ = ρ/ρ₀`, `a/a₀ = √θ`, `μ/μ₀`
  (referencia = nivel del mar ISA). Son adimensionales → iguales en SI e imperial.

### Edge cases / Condiciones de falla

| Causa | Resultado |
|---|---|
| `h < 0` o `h > 36.089 ft` | Entrada inválida: mensaje de fuera de rango, no calcula |
| Entrada vacía o no numérica | Validación: mensaje de error, no calcula |
| `h` en los extremos (0 / 36.089 ft) | Válido; calcula normalmente |

---

## FG-2 — Cálculo por interpolación (tabla generada por fórmula)

### Objetivo

Calcular el mismo set de magnitudes mediante **interpolación lineal** dentro de una
**tabla generada por las fórmulas ISA** a un paso configurable, para luego contrastar
contra el método analítico.

### Configuraciones

| Configuración | Default | Alternativas |
|---|---|---|
| Paso de la tabla `Δh` | 1.000 ft | Configurable por el usuario |
| Rango de la tabla | 0–36.089 ft | Fijo en v1 |
| Origen de los nodos | Generado por fórmula ISA | Fijo en v1 |

### Flujo

1. Se genera (o regenera al cambiar `Δh`) la tabla de **nodos** desde 0 hasta 36.089 ft
   con paso `Δh` (en ft). Cada nodo guarda `T, P, ρ, μ` calculados con las fórmulas de FG-1.
2. Para la altitud `h` ingresada, se localizan los nodos que la encierran
   `h_i ≤ h ≤ h_{i+1}`.
3. Se **interpola linealmente cada columna** tabulada:
   `X(h) = X_i + (X_{i+1} − X_i)·(h − h_i)/(h_{i+1} − h_i)` para `T, P, ρ, μ`.
4. Se **derivan** de los valores interpolados: `ν = μ_interp / ρ_interp`,
   `a = √(γ·R·T_interp)`, y todos los relativos (θ, δ, σ, a/a₀, μ/μ₀).

### Reglas

- La tabla se **genera por fórmula**, no se embebe una tabla publicada. Esto deja a la
  **interpolación como única fuente de error** y permite estudiar cómo el paso `Δh`
  afecta ese error.
- `μ` se **interpola directamente** desde su columna (precalculada con Sutherland en
  cada nodo) → `μ` tiene su propio error de interpolación, comparable contra el
  analítico.
- `ν` y `a` se **derivan** de los valores interpolados (`T, ρ, μ`), igual que en el
  método analítico, para que ambos métodos los obtengan de la misma forma.
- En la tropósfera `T` es lineal → su interpolación es prácticamente exacta; el error
  real aparece en `P, ρ, μ` (no lineales). Es el comportamiento esperado.

### Edge cases / Condiciones de falla

| Causa | Resultado |
|---|---|
| `h` coincide exactamente con un nodo | Resultado = valor del nodo (error de interpolación ≈ 0) |
| `Δh` no divide exacto 36.089 ft | El último tramo es más corto; la interpolación sigue válida |
| `Δh` ≤ 0 o mayor que el rango | Validación: paso inválido, no genera tabla |
| `h` fuera de `[0, 36.089] ft` | Misma validación de rango que FG-1 |

---

## FG-3 — Comparación lado a lado + diferencia/error

### Objetivo

Presentar, para cada magnitud, el valor **analítico** y el valor por **interpolación**
en paralelo, junto con su **diferencia absoluta** y su **error relativo**.

### Configuraciones

| Configuración | Default | Alternativas |
|---|---|---|
| Referencia para el error | Analítico (valor "exacto") | — |
| Formato del error | Absoluto + relativo (%) | — |

### Flujo

1. Se ejecutan FG-1 (analítico) y FG-2 (interpolación) sobre la misma altitud `h`.
2. Por cada magnitud se muestra: valor analítico, valor interpolado, **Δ = interp −
   analítico** y **ε = (interp − analítico)/analítico · 100 %**.
3. La vista muestra cada magnitud absoluta en **SI e imperial** a la vez; los relativos son
   adimensionales (valor único).

### Reglas

- El **método analítico es la referencia** (valor de comparación) para el cálculo del
  error.
- Se espera `ε ≈ 0` en `T` (y derivados de `T` como `a`), y `ε` apreciable en `P, ρ, μ`
  según el paso `Δh`. Reducir `Δh` reduce el error.

### Edge cases / Condiciones de falla

| Causa | Resultado |
|---|---|
| `h` coincide con un nodo | Δ ≈ 0 y ε ≈ 0 en todas las magnitudes |
| Magnitud con valor analítico = 0 | El error relativo no aplica; se muestra solo Δ (no ocurre en el rango ISA, pero queda contemplado) |

---

## Transversales

### Sistema de unidades (SI ↔ imperial)

Los resultados se muestran en **SI e imperial simultáneamente** (sin toggle): cada
magnitud absoluta aparece en ambos sistemas. Convención aeronáutica para imperial.

| Magnitud de salida | SI | Imperial |
|---|---|---|
| Temperatura | K (°C display) | °R (°F display) |
| Presión | Pa | lbf/ft² (psf) |
| Densidad | kg/m³ | slug/ft³ |
| Viscosidad dinámica μ | Pa·s | slug/(ft·s) |
| Viscosidad cinemática ν | m²/s | ft²/s |
| Velocidad del sonido a | m/s | ft/s |
| Relativos (θ, δ, σ, a/a₀, μ/μ₀) | adimensional | adimensional |

**Unidad de la altitud de entrada:** la altitud (y el paso de la tabla) se ingresan con
su propia unidad `altitudeUnit` (**m** o **ft**) y se **normalizan a ft** internamente
(unidad canónica). Es independiente de las unidades de salida (siempre SI e imperial a la vez).

**Regla:** la altitud se maneja en **ft** (canónica) y el resto en unidades base SI; la
entrada se normaliza desde `altitudeUnit` a ft, y la salida se entrega en SI **e** imperial a la vez.

### Validación de entrada y rango

| Pieza | Definición |
|---|---|
| Rango válido | `0 ≤ h ≤ 36.089 ft` geopotencial (≈ `0–11.000 m`); la entrada se normaliza desde `altitudeUnit` a ft antes de validar |
| Entrada no numérica / vacía | Bloquea el cálculo con mensaje de validación |
| Paso `Δh` (interpolación) | `> 0` y `≤ 36.089 ft` equivalente; expresado en `altitudeUnit` |

### Formato y precisión numérica

| Pieza | Definición |
|---|---|
| Cifras significativas | Default 5 |
| Notación científica | Para magnitudes con órdenes extremos (μ, ν, y P/ρ cuando corresponda) |
| Error relativo | En porcentaje, con signo |

### Fórmulas de conversión (referencia)

Apartado de **referencia** (contenido estático en el frontend) que muestra, por cada
magnitud, la fórmula/factor para pasar de un sistema a otro:

| Ítem | SI ↔ Imperial | Factor / fórmula |
|---|---|---|
| Altitud | m ↔ ft | `1 ft = 0.3048 m` |
| Temperatura | K ↔ °R | `°R = K × 1.8` |
| Presión | Pa ↔ lbf/ft² (psf) | `1 psf = 47.8803 Pa` |
| Densidad | kg/m³ ↔ slug/ft³ | `1 slug/ft³ = 515.379 kg/m³` |
| Viscosidad dinámica μ | Pa·s ↔ slug/(ft·s) | `1 slug/(ft·s) = 47.8803 Pa·s` |
| Viscosidad cinemática ν | m²/s ↔ ft²/s | `1 ft²/s = 0.092903 m²/s` |
| Velocidad del sonido a | m/s ↔ ft/s | `1 ft/s = 0.3048 m/s` |
| Relativos (θ, δ, σ, a/a₀, μ/μ₀) | adimensionales | — (sin conversión) |

### Arquitectura cliente-servidor / multiplataforma

| Pieza | Definición |
|---|---|
| Cálculo | Lo ejecuta una **API** (backend); el frontend no calcula |
| Frontend | Solo presenta resultados obtenidos por petición a la API |
| Targets del frontend | Windows, Linux y Web |
| Conectividad | Requiere alcanzar la API para calcular |
| Empaquetado / build | Web vía contenedor + build de escritorio (Win/Linux) documentado |
| Stack / detalle | A definir en `/product-discovery-technical` |

---

## Internacionalización (i18n)

**Idiomas v1:** Español (único).
**Reglas:**
- UI íntegramente en español. Sin infraestructura multi-idioma en v1.
- Símbolos y unidades se muestran en notación estándar internacional (K, Pa, ft, etc.).

---

## Métricas / Criterio de Éxito

Al ser una herramienta personal, **no hay métricas de negocio**. El criterio de éxito es
de **corrección**:

- El método analítico reproduce el **estándar ISA exacto** (doble precisión). Se
  **cross-checkea** contra la **tabla ISA de referencia** (UTN —
  `docs/references/atmosfera_tipo_internacional_ISA.pdf`, en ft, redondeada a 3 decimales)
  dentro de su tolerancia de redondeo: la tabla valida, no limita la precisión.
- La comparación FG-3 refleja el comportamiento esperado: error ≈ 0 en `T`, error
  apreciable y decreciente con `Δh` en `P, ρ, μ`.

---

## Dependencias y Bloqueos Abiertos

- **Tabla ISA de referencia para validación** — fijada: tabla **UTN en ft**
  (`docs/references/atmosfera_tipo_internacional_ISA.pdf`). Insumo de testing del método
  analítico en el rango 0–36.089 ft.
- **Definiciones técnicas (se cierran en `/product-discovery-technical`)** — lenguaje/stack
  de la API, framework del frontend, protocolo de comunicación frontend↔API, empaquetado
  web (contenedor) y build de escritorio (Windows/Linux) con su documentación.
  *Preferencia del usuario a formalizar allí:* API en **Go**, frontend en **Flutter**,
  **Dockerfile** para web y **documentación de build** para Windows/Linux.
- Sin otras dependencias externas de software ni de datos.

---

## Fuera de Alcance — Preguntas Abiertas

- **Capas sobre 11 km** (tropopausa, estratósfera, etc.) — diferido; v1 es solo
  tropósfera. La arquitectura del modelo debería dejar lugar a sumar capas después.
- **Altitud geométrica y conversión geopotencial↔geométrica** — diferido; el usuario lo
  acotó "por el momento" a geopotencial.
- **Atmósfera no estándar** (desviación ISA, offset de temperatura) — fuera de v1.
- **Modo batch / generación de tabla por rango** — fuera de v1 (solo punto único).
- **Exportar / historial de cálculos** — fuera de v1; *copiar resultados al
  portapapeles* queda como opcional de bajo costo.
- **Relativo `ν/ν₀`** — v1 incluye `μ/μ₀`; `ν/ν₀` queda como posible agregado futuro.

---

## Decisiones Tomadas

| # | Tema | Decisión y por qué |
|---|---|---|
| 1 | Naturaleza del producto | Herramienta personal de ingeniería, mono-usuario, sin cuentas ni autenticación — uso individual |
| 2 | Rango de altitud v1 | Tropósfera 0–36.089 ft (≡ 0–11.000 m) geopotencial, una capa, gradiente −6.5 K/km, piso en 0 — alcance declarado; simplifica el modelo a una sola capa |
| 3 | Métodos de cálculo | Analítico (fórmulas ISA cerradas) + interpolación lineal — comparar ambos es el objetivo central del producto |
| 4 | Origen de la tabla de interpolación | Generada por fórmula en grilla de ft, paso configurable (default 1.000 ft) — aísla el error de interpolación y permite estudiar el efecto del paso; evita transcribir/embeber una tabla publicada |
| 5 | Viscosidad en interpolación | Columna μ precalculada (Sutherland) e interpolada directo — μ tiene su propio error de interpolación comparable contra el analítico |
| 6 | Derivación de ν y a en interpolación | ν=μ/ρ y a=√(γRT) se derivan de los valores interpolados (no se tabulan) — igual mecanismo que en el método analítico, mantiene la tabla en las magnitudes físicas primarias |
| 7 | Magnitudes de salida | T, P, ρ, μ, ν=μ/ρ, a=√(γRT) + relativos θ, δ, σ, a/a₀, μ/μ₀ — set pedido por el usuario; relativos respecto al nivel del mar ISA |
| 8 | Modo de uso | Punto único, ambos métodos lado a lado + diferencia/error — el usuario quiere comparar visualmente los dos métodos |
| 9 | Unidades | Resultados en SI **e** imperial mostrados simultáneamente (sin toggle) — el usuario los quiere ambos a la vez; los relativos son adimensionales |
| 10 | Altitud de entrada | Geopotencial; geométrica diferida. Unidad canónica interna = **ft** (alineada a la tabla de referencia) — la tabla ISA usada está en ft |
| 11 | Constantes del modelo | Estándar **exacto ISA 1976/ICAO**: R*=8.31432 J/(mol·K), M₀=0.0289644 kg/mol → R≈287.05287 J/(kg·K); T₀=288.15 K, P₀=101325 Pa, L=−6.5 K/km, g₀=9.80665 m/s², γ=1.4; Sutherland β=1.458e-6, S=110.4 K. ρ₀, a₀, μ₀ derivados en runtime (ver #21) |
| 12 | Referencia del error | El método analítico es el valor "exacto" de referencia; error = absoluto + relativo (%) — el analítico es cerrado/exacto frente a la interpolación |
| 13 | i18n | UI en español, un solo idioma en v1 — uso personal, no requiere multi-idioma |
| 14 | Export / historial | Fuera de alcance v1; copiar resultados al portapapeles, opcional — no esencial para el objetivo; se puede sumar después |
| 15 | Validación de rango | Entrada válida 0–36.089 ft (≈ 0–11.000 m); fuera de rango o no numérica bloquea el cálculo — evita extrapolar fuera de la capa modelada |
| 16 | Arquitectura cliente-servidor | El cálculo lo realiza una **API** (backend) y el **frontend solo muestra** los resultados obtenidos por petición — decisión explícita del usuario; reemplaza el enfoque "offline/local" inicial. El stack (Go/Flutter), la comunicación y el empaquetado (Docker/build de escritorio) se definen en `/product-discovery-technical` |
| 17 | Unidad de la altitud de entrada | Selector `altitudeUnit` (m/ft) para la entrada; se **normaliza a ft** internamente — el usuario lo pidió; ingreso flexible alineado a la tabla en ft |
| 18 | Tabla de referencia | Tabla ISA en ft (UTN — `docs/references/atmosfera_tipo_internacional_ISA.pdf`) como fuente de validación del método analítico — la usa el usuario; fija la unidad canónica (ft) y el techo de la tropósfera (36.089 ft) |
| 19 | Altitud en la respuesta | La API eco-devuelve la altitud en **m y ft** (ambas), sea cual sea la unidad de entrada — el usuario lo pidió; comodidad de tener las dos referencias |
| 20 | Sección de fórmulas de conversión | Apartado de referencia **estático en el frontend** con la fórmula/factor SI↔imperial (y m↔ft) por magnitud — el usuario lo pidió; al ser estático no requiere endpoint (factores conocidos) |
| 21 | Precisión numérica | Cálculo en doble precisión (float64) con las constantes **exactas ISA 1976/ICAO**; ρ₀, a₀, μ₀ y el exponente n se derivan en runtime (no se hardcodean redondeados); no se sustituyen por constantes físicas más nuevas (romperían la coherencia). La tabla UTN (3 decimales) es cross-check, no el techo de precisión — el usuario pidió máxima exactitud coherente |
