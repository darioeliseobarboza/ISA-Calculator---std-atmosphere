---
document: "UX User Flows"
surface: "app-calculadora"
version: "1.0"
date: 2026-06-21
status: "Draft - Punto de partida para discusión"
flows_count: 3
---

# UX User Flows — app-calculadora

> Flujos críticos internos de la superficie. **No son todos los flujos** —
> son los 3-5 que definen el valor del producto en esta superficie. Otros
> flujos derivan de estos o son operaciones secundarias. Si un flujo cruza
> a otra superficie, vive en `cross-surface-flows.md`, no acá.

> **Nota de superficie:** `app-calculadora` es mono-superficie y mono-usuario (NFR-S01, sin autenticación). No hay flujos cross-surface: nada de lo que ocurre acá cruza a otra superficie. El cálculo lo resuelve la API (`POST /v1/calculate`); el frontend solo arma el request y presenta la respuesta. Por eso "sin conexión" es un **estado de error de la superficie**, no un modo offline.

## Flujos Documentados

| # | Flujo | JTBD que resuelve | Audiencia |
|---|-------|-------------------|-----------|
| 1 | Calcular parámetros ISA y leer en doble unidad | "Cuando necesito los parámetros atmosféricos ISA a una altitud dada, quiero obtenerlos en SI e imperial a la vez, para no calcularlos a mano ni buscar en tablas" (JTBD-1) | ingeniero-tecnico |
| 2 | Comparar analítico vs. interpolación y estudiar el error según el paso | "Cuando estudio cómo cambia el error de interpolación según el muestreo de la tabla, quiero ajustar el paso y recalcular, para ver cómo se reduce el error" (JTBD-2 + JTBD-3) | ingeniero-tecnico |
| 3 | Consultar las fórmulas de conversión | "Cuando quiero verificar de dónde salen los números, quiero consultar las fórmulas/factores por magnitud, para no tratar el cálculo como caja negra" (gain de verificación, C-04) | ingeniero-tecnico |

## Flujo 1: Calcular parámetros ISA y leer en doble unidad

**JTBD que resuelve:** "Cuando necesito los parámetros atmosféricos ISA a una altitud dada, quiero ingresar la altitud geopotencial (en m o ft) y obtener T, P, ρ, μ, ν, a y los relativos en SI e imperial a la vez, para tener los valores sin calcularlos a mano ni buscar en tablas impresas." (JTBD-1)
**Audiencia:** ingeniero-tecnico ([research-context](../../audiences/ingeniero-tecnico/research-context.md))
**Trigger:** El usuario abre la app (P-01) y necesita los parámetros ISA de una altitud concreta. P-01 arranca en estado "vacío inicial": entrada disponible, bloque de resultados sin contenido.

### Happy path

1. En P-01, el usuario ingresa la altitud en el campo de entrada y selecciona la unidad (m o ft).
2. Dispara el cálculo (botón "Calcular" / Enter). P-01 pasa a estado "cargando": el bloque de resultados indica cálculo en curso; la entrada queda visible.
3. El frontend envía `POST /v1/calculate` con altitud, unidad y (si aplica FG-3) paso de tabla. La API valida y responde con las magnitudes.
4. P-01 renderiza el bloque de resultados: las 6 magnitudes (T, P, ρ, μ, ν, a) y los relativos (θ, δ, σ, a/a₀, μ/μ₀), cada una en SI **e** imperial a la vez, con 5 cifras significativas y notación científica donde corresponde (μ, ν, P/ρ).
5. El usuario lee los valores. La entrada queda intacta para encadenar otro cálculo cambiando la altitud sin reingresar nada más.

### Caminos alternativos

- **Cambio de altitud y recálculo** — El usuario corrige la altitud (o la unidad) y vuelve a calcular sin recargar la pantalla. El bloque de resultados se reemplaza con el nuevo cálculo; el anterior no se conserva (sin historial en v1).
- **Lectura priorizando un sistema** — La doble unidad se muestra siempre; el usuario lee el sistema que le interesa de un vistazo sin tener que alternar un toggle SI↔imperial (resuelve el pain de "alternar para comparar"). La jerarquía visual SI vs. imperial está sin definir (Pregunta abierta 4 del product-map).
- **Solo método analítico (recorte FG-2)** — Si la entrega es FG-2, el bloque muestra únicamente el analítico; las columnas de interpolación/error no se renderizan. El flujo de entrada→cálculo→lectura es idéntico.

### Errores y recuperación

- **Altitud fuera de rango (`outOfRange`)** — El usuario ingresa una altitud por encima del límite del modelo (> 36.089 ft / equivalente en m). La API responde 400 con `error.code: outOfRange`. P-01 muestra un aviso claro de límite del modelo junto al campo de altitud, **no** presenta resultados, y conserva el valor ingresado. Recuperación: el usuario corrige la altitud y reintenta; no se queda con un resultado silenciosamente erróneo. `[fuente: PRD C-03; research-context — hipótesis fuera de rango]`
- **Entrada no numérica (`invalidInput`)** — El usuario ingresa texto o un valor no parseable. La API responde 400 con `error.code: invalidInput` (idealmente la validación de formato evita el viaje innecesario, pero el `error.code` es la fuente de verdad). P-01 marca el campo de altitud con el aviso de entrada inválida y no calcula. Recuperación: el usuario corrige el dato y reintenta. `[fuente: PRD C-03]`
- **Sin conexión / error de API** — La red no responde o la API devuelve 5xx. P-01 muestra el estado de error de conectividad **conservando** la entrada del usuario y ofrece reintentar. No es modo offline: el frontend no puede calcular por sí mismo. Recuperación: el usuario reintenta cuando vuelve la conexión, sin reingresar la altitud. `[fuente: PRD NFR-PL02; research-context — Restricciones de Contexto]`

### Estado final

P-01 muestra el bloque de resultados con las magnitudes y relativos de la altitud ingresada, en SI e imperial, con el formato numérico esperado. La entrada permanece para iniciar un nuevo cálculo. El sistema no persiste estado entre sesiones (sin historial, sin cuenta).

### Criterios de éxito

- El usuario obtiene todas las magnitudes de una altitud en un único cálculo, sin reingresar el dato.
- El usuario lee SI e imperial a la vez, sin alternar un toggle de unidades.
- Ante un dato fuera de rango o no numérico, el usuario recibe un aviso claro y no un resultado erróneo, sin perder lo que ya escribió.
- Una caída de la API no descarta la entrada: el usuario reintenta sin retipear.

## Flujo 2: Comparar analítico vs. interpolación y estudiar el error según el paso

> **Alcance — FG-3.** Este flujo **no se ejercita en FG-2 (REQ-002)**: requiere el método de interpolación, la comparación y el control de paso de tabla, todos parte de FG-3. En FG-2 la pantalla muestra solo el método analítico y el control de paso está deshabilitado.

**JTBD que resuelve:** "Cuando quiero saber cuánto se desvía la interpolación del valor exacto, quiero verlos lado a lado con su diferencia y error relativo; y cuando estudio cómo cambia ese error según el muestreo, quiero ajustar el paso de la tabla y recalcular, para ver cómo se reduce el error al disminuir Δh." (JTBD-2 + JTBD-3)
**Audiencia:** ingeniero-tecnico ([research-context](../../audiences/ingeniero-tecnico/research-context.md))
**Trigger:** El usuario ya tiene (o realiza) un cálculo en P-01 y quiere dimensionar el error de interpolación o estudiar su sensibilidad al paso de la tabla. (Flujo disponible con FG-3.)

### Happy path

1. En P-01, con la comparación activa, el usuario calcula a una altitud dada (como en Flujo 1). El bloque de resultados muestra, por magnitud, el valor **analítico**, el de **interpolación** y la comparación: diferencia absoluta (Δ) y error relativo (%).
2. El usuario lee primero el analítico como valor de referencia y contrasta la interpolación y el error contra él (hipótesis de comportamiento del research-context).
3. Para estudiar la sensibilidad, abre el control de paso de tabla (O-02) desde P-01 y ajusta `tableStep` (en la unidad activa; default 1.000 ft). El cambio afecta solo al método de interpolación.
4. El ajuste dispara el recálculo (`POST /v1/calculate` con el nuevo paso). P-01 vuelve a estado "cargando" en el bloque de resultados.
5. P-01 actualiza la comparación: con un paso menor, el error relativo por magnitud disminuye. El usuario observa la reducción del error al reducir Δh.

### Caminos alternativos

- **Varias iteraciones de paso** — El usuario repite el ajuste de `tableStep` varias veces (paso decreciente) para ver la tendencia del error. Cada cambio recalcula solo la interpolación; el analítico permanece estable como referencia.
- **Paso editado inline vs. overlay** — Según resuelva la Pregunta abierta 1 del product-map, el paso puede editarse inline en la entrada o vía popover O-02. El flujo lógico (ajustar → recalcular → comparar) es el mismo.
- **Comparación siempre visible vs. conmutable** — Según la Pregunta abierta 2 del product-map, la comparación puede estar siempre presente o detrás de un toggle "solo analítico / comparación". Si está conmutable, el paso 1 incluye activar la vista de comparación.

### Errores y recuperación

- **Paso de tabla inválido (`invalidStep`)** — El usuario ingresa un paso no válido (≤ 0, no numérico, o fuera de un mínimo razonable). La API responde 400 con `error.code: invalidStep`. P-01 muestra el aviso junto al control de paso, no recalcula la interpolación y conserva el último resultado válido visible. Recuperación: el usuario corrige el paso (o vuelve al default 1.000 ft) y reintenta. `[fuente: PRD C-02/C-03; product-map — Estados Globales]`
- **Altitud fuera de rango (`outOfRange`) o entrada no numérica (`invalidInput`)** — Mismo manejo que en Flujo 1: aviso junto al campo de altitud, sin resultados, entrada conservada. Aplica antes de poder comparar nada.
- **Sin conexión / error de API durante el recálculo** — Al ajustar el paso, si la API no responde, P-01 muestra el estado de error de conectividad conservando tanto la altitud como el paso ingresado, y ofrece reintentar. El resultado anterior puede quedar visible marcado como desactualizado. Recuperación: reintentar al volver la conexión, sin reconfigurar. `[fuente: PRD NFR-PL02; research-context — Restricciones de Contexto]`

### Estado final

P-01 muestra la comparación analítico | interpolación | Δ/error % por magnitud, para la altitud y el paso vigentes. Tras iterar el paso, el usuario tiene evidencia visible de cómo el error de interpolación se reduce al disminuir Δh. No se persiste la secuencia de pasos probados (sin historial en v1).

### Criterios de éxito

- El usuario ve el error de interpolación cuantificado (Δ absoluto + error relativo %) en la misma vista, sin calcular la resta él mismo.
- El usuario puede ajustar el paso y observar el efecto sobre el error sin saltar de pantalla ni reingresar la altitud.
- Un paso inválido se avisa de forma localizada y no descarta el último cálculo válido.
- El criterio de éxito del PRD se hace observable: al reducir el paso, el error relativo baja.

## Flujo 3: Consultar las fórmulas de conversión

**JTBD que resuelve:** "Cuando quiero verificar de dónde salen los números, quiero consultar las fórmulas/factores de conversión por magnitud, para no tratar el cálculo como caja negra." (gain de verificación — C-04 / F-02)
**Audiencia:** ingeniero-tecnico ([research-context](../../audiences/ingeniero-tecnico/research-context.md))
**Trigger:** Estando en P-01 (con o sin un cálculo a la vista), el usuario quiere verificar la fórmula o el factor SI↔imperial de una magnitud. Click en btn-fórmulas.

### Happy path

1. En P-01, el usuario hace click en btn-fórmulas (header o barra de acciones).
2. Se abre el drawer O-01 (panel lateral) sin abandonar P-01: los resultados del cálculo en curso quedan visibles detrás.
3. O-01 presenta contenido **estático** de referencia, organizado por magnitud (altitud m↔ft, T, P, ρ, μ, ν, a): fórmula y/o factor de conversión SI↔imperial. Los relativos figuran como adimensionales. El drawer no calcula.
4. El usuario lee la fórmula/factor de la magnitud que le interesa y la contrasta con el valor que ve en el cálculo de P-01.
5. El usuario cierra el drawer y vuelve a P-01 con el cálculo en curso intacto.

### Caminos alternativos

- **Consulta sin cálculo previo** — El usuario abre O-01 antes de calcular nada (solo quiere ver las fórmulas). El drawer funciona igual; al cerrarlo vuelve al estado "vacío inicial" de P-01.
- **Consulta prolongada/comparada** — Si la Pregunta abierta 3 del product-map concluye que la consulta es prolongada y comparada contra los resultados, O-01 podría migrar de drawer a panel persistente lado a lado. El contenido y el propósito (verificar de dónde salen los números) no cambian.

### Errores y recuperación

- **(No aplica error de API)** — O-01 es contenido estático servido por el frontend; **no** depende de `POST /v1/calculate`. No tiene estado fuera de rango, entrada inválida ni dependencia de conectividad propia para mostrarse. Es la diferencia clave frente a los Flujos 1 y 2.
- **Drawer abierto sobre un estado de error de P-01** — Si P-01 está mostrando un error de cálculo (fuera de rango / sin conexión) y el usuario abre las fórmulas, O-01 se muestra normalmente; al cerrarlo, P-01 conserva su estado de error y la entrada. Recuperación: el usuario sigue desde donde estaba.

### Estado final

El usuario verificó la fórmula/factor que necesitaba y volvió a P-01 sin perder el cálculo en curso. No cambió ningún estado del sistema: la consulta es de solo lectura.

### Criterios de éxito

- El usuario accede a las fórmulas a un clic desde P-01 y vuelve sin perder el cálculo que estaba mirando.
- El usuario encuentra la referencia organizada por magnitud, con nomenclatura estándar y sobria (sin rótulos inflados).
- La consulta no interrumpe ni descarta el trabajo en curso: el cálculo sigue visible/recuperable detrás del drawer.

---

**Relacionados:** Las pantallas usadas en estos flujos están inventariadas en `product-map.md` de esta superficie. Los flujos que cruzan a otras superficies viven en `../cross-surface-flows.md` (no aplica: producto mono-superficie).
