---
document: "UX Research Context"
audience: "ingeniero-tecnico"
version: "1.0"
date: 2026-06-21
status: "hipótesis-preliminar"
---

# UX Research Context — ingeniero-tecnico

> Caracterización de la audiencia. **Todo lo que sigue es hipótesis** hasta
> que se valide con usuarios reales. Cada item está trazado a su fuente
> (PRD, benchmark, input-cliente). Items sin fuente trazable no se incluyen.

## Persona Genérica

- **Rol:** Usuario técnico / ingeniero que usa la herramienta de forma personal para obtener los parámetros ISA de una altitud y comparar métodos de cálculo (rol U-01 del PRD). Único usuario del producto; sin roles, cuentas ni autenticación.
- **Contexto de uso:** Sesiones puntuales de cálculo en escritorio. Ingresa una altitud geopotencial, lee las magnitudes resultantes en SI e imperial y, cuando aplica, contrasta analítico vs. interpolación. No usa la herramienta de forma continua; la abre cuando necesita un valor o verificar el error de un método. `[fuente: PRD §Usuarios Objetivo - U-01; PRD §Contexto - Naturaleza]`
- **Expertise técnico:** Alto en el dominio físico. Maneja la nomenclatura estándar (T, P, ρ, μ, ν, a, θ, δ, σ) sin necesidad de explicaciones, conoce el modelo ISA y la diferencia entre altitud geopotencial y geométrica, y entiende qué es el error de interpolación. Espera nomenclatura sobria y verificable, no rótulos inflados. `[fuente: benchmark - Anti-patrón "etiquetas recargadas"; PRD §Magnitudes]`
- **Frecuencia de uso esperada:** Esporádica / bajo demanda. No hay base en el PRD para suponer uso intensivo o continuo; es una herramienta personal de consulta. La frecuencia real es desconocida (ver "Lo que NO sabemos"). `[fuente: PRD §Contexto - Naturaleza (herramienta personal, mono-usuario)]`
- **Dispositivo principal:** Desktop (Windows/Linux/Web), diseño desktop-first a 1200×800. El producto se distribuye también a Web, pero el caso primario declarado es escritorio. `[fuente: PRD §G-03 y NFR-PL01; product-overview.md - Plataforma]`

## Jobs To Be Done

1. **Cuando** necesito los parámetros atmosféricos ISA a una altitud dada, **quiero** ingresar la altitud geopotencial (en m o ft) y obtener T, P, ρ, μ, ν, a y los relativos (θ, δ, σ, a/a₀, μ/μ₀) en SI e imperial a la vez, **para** tener los valores sin calcularlos a mano ni buscar en tablas impresas.
   `[fuente: PRD §3 - Capability C-01; PRD §G-01]`

2. **Cuando** quiero saber cuánto se desvía el método de interpolación del valor exacto, **quiero** ver el resultado analítico y el de interpolación lado a lado con su diferencia absoluta y error relativo por magnitud, **para** dimensionar y cuantificar el error de interpolación.
   `[fuente: PRD §3 - Capability C-01; PRD §G-02; PRD §Planteo del Problema (valor central = comparar y cuantificar el error)]`

3. **Cuando** estudio cómo cambia el error de interpolación según el muestreo de la tabla, **quiero** ajustar el paso de la tabla y recalcular, **para** ver cómo se reduce el error al disminuir el paso.
   `[fuente: PRD §3 - Capability C-02; PRD §Criterios de Éxito (ε disminuye al reducir Δh)]`

## Pains

- Resolver los parámetros ISA a mano, con tablas impresas o planillas sueltas, es lento y propenso a error. `[fuente: PRD §Planteo del Problema]`
- No puede ver fácilmente cuánto difiere un método de cálculo de otro: los valores quedan en fuentes separadas y la diferencia hay que calcularla aparte. `[fuente: PRD §Planteo del Problema; PRD §G-02]`
- Cuando consulta calculadoras existentes, debe alternar un toggle/dropdown SI↔imperial para comparar sistemas y no puede leer ambos de un vistazo. `[fuente: benchmark - Anti-patrón "toggle SI/imperial que obliga a alternar" (Digital Dutch, AeroToolbox)]`

## Gains

- Obtiene las 6 magnitudes y los relativos de una altitud en un solo cálculo, leyendo SI e imperial a la vez sin reingresar el dato ni alternar unidades. `[fuente: PRD §3 - Capability C-01; PRD §NFR-U03; benchmark - patrón "SI+imperial simultáneo" (Luiz Monteiro, AviationHunt)]`
- Ve el error de interpolación cuantificado (diferencia absoluta + error relativo %) en la misma vista, sin tener que calcular la resta él mismo. `[fuente: PRD §3 - Capability C-01; PRD §G-02]`
- Puede verificar de dónde salen los números consultando las fórmulas/factores de conversión por magnitud, sin tratar el cálculo como caja negra. `[fuente: PRD §3 - Capability C-04; benchmark - patrón "sección de fórmulas/constantes" (AviationHunt, MechaniCalc/Uconeer)]`

## Hipótesis de Comportamiento

- Lee primero el resultado analítico (lo trata como valor de referencia/exacto) y mira la interpolación y el error como contraste secundario, no al revés. `[estado: hipótesis | fuerza: inferida-PRD]` (base: PRD declara el analítico como ground-truth y la comparación como su contra-cara)
- Espera que la entrada sea altitud **geopotencial** y que la salida incluya ambas viscosidades (μ y ν); si faltara alguna o se usara altitud geométrica sin aclararlo, el resultado contradiría su modelo mental traído de herramientas como `atmosisa`. `[estado: hipótesis | fuerza: inferida-benchmark]` (base: benchmark - MATLAB `atmosisa`)
- Cambia el paso de la tabla pocas veces y de forma exploratoria (para estudiar el efecto del paso), no en cada cálculo; el default de 1.000 ft le sirve para el uso habitual. `[estado: hipótesis | fuerza: inferida-PRD]` (base: PRD C-02 + decisión "paso configurable, default 1.000 ft")
- Prefiere nomenclatura estándar y sobria (T, P, ρ, μ, ν, a) y descarta como ruido los rótulos inflados; rótulos verbosos le restan claridad sin agregar precisión. `[estado: hipótesis | fuerza: inferida-benchmark]` (base: benchmark - Anti-patrón AviationHunt)
- Cuando ingresa una altitud fuera de rango (> 36.089 ft) o un dato no numérico, espera un aviso claro de límite del modelo y no un resultado silenciosamente erróneo. `[estado: hipótesis | fuerza: inferida-PRD]` (base: PRD C-03 - validación con `error.code`; benchmark - manejo de límites en `atmosisa`)

## Restricciones de Contexto

- **Requiere conectividad con la API** — El cálculo lo hace el backend; sin red, el frontend no puede calcular y debe mostrar error (no es offline). El diseño debe contemplar el estado "sin conexión / error de API" como un estado de primera clase. `[fuente: PRD §Restricciones - Conectividad; NFR-PL02]`
- **Precisión y formato numérico** — Espera 5 cifras significativas y notación científica para μ, ν y P/ρ cuando corresponda; el formato de los números no es cosmético, es parte de la utilidad para esta audiencia. `[fuente: PRD §NFR-U02]`
- **UI en español, un idioma** — Toda la interfaz en español en v1; la nomenclatura física estándar (símbolos) convive con el texto en español. `[fuente: PRD §NFR-U01]`
- **Desktop-first, multiplataforma** — Distribuido a Windows, Linux y Web (Flutter); el layout de comparación lado a lado se piensa para escritorio a 1200×800. `[fuente: PRD §NFR-PL01; product-overview.md]`

## Lo que NO Sabemos

- ¿Con qué frecuencia real usa la herramienta y en sesiones de qué duración? El PRD solo dice "personal/mono-usuario"; no hay datos de frecuencia ni de cuántos cálculos hace por sesión. Requiere observación o entrevista con el usuario real.
- ¿Cuál de los tres JTBD es el predominante: obtener valores (G-01), cuantificar el error (G-02) o estudiar el efecto del paso (C-02)? El PRD posiciona la comparación como "valor central", pero no está validado que el uso real lo confirme.
- ¿Usa la salida imperial tanto como la SI, o el imperial es secundario y el doble-unidad simultáneo es solo un "por las dudas"? Esto afecta cuánta jerarquía visual merece cada sistema.
- ¿Qué hace cuando la API no responde o tira error de validación? Asumimos que entiende el mensaje de límite del modelo, pero no validamos qué recuperación espera (reintentar, corregir el dato, otra cosa).
- ¿Necesita comparar/retener varios cálculos a la vez, o le alcanza con un cálculo puntual por sesión? El historial y el modo batch están fuera de v1, pero no se validó si la ausencia de historial es un problema real para esta audiencia.
- ¿El paso de la tabla es algo que toca en la práctica, o es una capacidad que casi nunca usa? Si es marginal, no debería competir por espacio con la entrada principal de altitud.

---

**Estado:** Documento en estado `hipótesis-preliminar`. Para promoverlo a `validado`, ejecutar entrevistas reales y actualizar in-place el estado de cada hipótesis.

**Consumido por:** Los `product-map.md` y `user-flows.md` de las superficies que esta audiencia usa (ver matriz en `product-overview.md`).
