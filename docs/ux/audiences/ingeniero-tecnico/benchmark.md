---
document: "UX Benchmark"
audience: "ingeniero-tecnico"
version: "1.0"
date: 2026-06-21
status: "Hipótesis inicial - Referencias de partida"
---

# UX Benchmark — ingeniero-tecnico

> Referentes mentales que esta audiencia trae al producto. Productos que
> ya usa o conoce, y de los que importa expectativas. No es auditoría
> exhaustiva — es punto de partida para entender qué patrones ya conoce
> el usuario y qué espera encontrar.

## Competidores Directos

### Luiz Monteiro — Standard Atmosphere Calculator

- **Qué resuelve:** Calculadora de atmósfera estándar (modelo 1976) muy usada en el ámbito aeronáutico; cubre el mismo conjunto de magnitudes que nuestro producto, incluyendo viscosidad dinámica y cinemática.
- **Cómo lo resuelve:** Formulario con ~28 propiedades atmosféricas; el usuario ingresa **cualquier** campo (altitud geométrica, geopotencial, T, P, ρ, viscosidad…) y obtiene el resto. Para cada magnitud muestra **SI e imperial simultáneamente** en el mismo campo (ej. presión en Pa, hPa, lbf/ft², inHg, mmHg, lbf/in²; temperatura en K, °R, °C, °F). Incluye checkbox "Show additional decimal point" para ajustar precisión.
- **A tomar:** Mostrar SI e imperial a la vez por magnitud (no toggle) — coincide con la propuesta de doble unidad del producto. Control de precisión/decimales como opción del usuario. Cobertura explícita de viscosidad dinámica **y** cinemática, que la mayoría de los competidores omite.
- **A evitar:** Densidad de información alta y layout de formulario plano con 28 filas; el usuario debe escanear mucho para encontrar las 6 magnitudes que le importan. No separa visualmente "lo que ingresé" de "lo que se calculó".
- **Fuente:** http://www.luizmonteiro.com/stdatm.aspx (verificado vía WebFetch, junio 2026).

### Digital Dutch — 1976 Standard Atmosphere Calculator

- **Qué resuelve:** Calculadora de atmósfera estándar 1976 con T, P, ρ, velocidad del sonido y viscosidad dinámica a una altitud dada.
- **Cómo lo resuelve:** Entrada de altitud con selector de unidad (ft, km, m, millas náuticas) y offset de temperatura opcional. Cada magnitud se muestra en múltiples unidades (T: °C/K/°F/°R/Réaumur; P: atm/inHg/mbar/Pa/lbf-ft²/psi; ρ: kg/m³, sigma, slug/ft³; etc.). Ofrece vistas separadas: **Calculator**, **Table**, **Graphs** y **Options**, con toggle "SI Units | English/US Units".
- **A tomar:** La existencia de una vista **Table** además del cálculo puntual valida que esta audiencia espera poder consultar la tabla (relevante para el método por interpolación en FG-3). Múltiples unidades por magnitud cubiertas con claridad.
- **A evitar:** El toggle SI/imperial obliga a alternar para comparar sistemas; no permite leer ambos de un vistazo. La separación en pestañas (Calculator/Table/Graphs) parte la experiencia en lugar de integrar comparación.
- **Fuente:** https://www.digitaldutch.com/atmoscalc/ (verificado vía WebFetch, junio 2026).

### AeroToolbox — Standard Atmosphere Calculator

- **Qué resuelve:** Calculadora de atmósfera estándar (modelo US 1976) orientada a performance de aeronaves; T, presión, densidad, velocidad del sonido, viscosidad y densidad relativa.
- **Cómo lo resuelve:** Dos modos de entrada (altitud + temperatura del aire, o altitud + offset de temperatura), altitud en ft o m. Resultados por categoría con **dropdowns de unidad por magnitud** (P en Pa/mbar/bar/inHg/mmHg/psi; ρ en kg/m³, slug/ft³, lb/ft³; viscosidad en Pa·s, Poise, cP, lbf·s/ft²). Incluye densidad relativa (respecto a nivel del mar ISA).
- **A tomar:** Exposición explícita de la **densidad relativa** respecto al nivel del mar ISA — ancla la utilidad de los relativos (θ, δ, σ) que el producto muestra. Modo de entrada simple altitud→resultados.
- **A evitar:** Cambio de unidad vía dropdown por magnitud: el usuario elige una unidad a la vez, no ve SI e imperial en paralelo. No se identificó vista de tabla ni gráfico en esta verificación.
- **Fuente:** https://aerotoolbox.com/atmcalc/ (verificado vía WebFetch, junio 2026).

### AviationHunt — ICAO Standard Atmosphere Calculator

- **Qué resuelve:** Calculadora ICAO ISA multicapa (validada hasta ~32.000 m) para T, P, ρ y velocidad del sonido.
- **Cómo lo resuelve:** Un único campo de altitud con toggle de unidad (Meters/Feet) y botón "COMPUTE METRICS". Resultados en **tarjetas por magnitud** con SI e imperial mostrados **simultáneamente en filas separadas** (T en °C/K/°F; P en Pa/PSI/inHg; ρ en kg/m³/slug; a en m/s, ft/s, knots). Placeholder con guiones ("–") antes de calcular. Botón "RESET CALCULATOR". Sección "How It's Calculated" con las ecuaciones y constantes (ej. R = 287.05287 J/kg·K).
- **A tomar:** Entrada minimalista (un campo + unidad + botón) alineada con el JTBD "altitud → parámetros". Estados de placeholder claros antes del cálculo. Sección de fórmulas/constantes visible — valida la sección de fórmulas de conversión del producto. SI e imperial en filas separadas dentro de cada tarjeta.
- **A evitar:** No cubre viscosidad ni relativos (cobertura más pobre que el producto). La nomenclatura de etiquetas es recargada ("Ambient Thermodynamic Temperature", "Air Mass Density Matrix") y agrega ruido sin valor para un ingeniero.
- **Fuente:** https://www.aviationhunt.com/standard-atmosphere-calculator/ (verificado vía WebFetch, junio 2026).

## Referentes Indirectos

### MATLAB `atmosisa` (categoría: cómputo técnico / Aerospace Toolbox)

- **Qué expectativa trae a este producto:** La definición "canónica" de qué se calcula a partir de una altitud geopotencial. La función devuelve exactamente las **seis** magnitudes del producto a partir de altitud geopotencial: temperatura (K), velocidad del sonido (m/s), presión (Pa), densidad (kg/m³), viscosidad cinemática (m²/s) y viscosidad dinámica (kg/m·s).
- **Cómo se manifiesta:** El ingeniero que usa MATLAB espera que la entrada sea **altitud geopotencial** (no geométrica) y que el conjunto de salidas incluya ambas viscosidades. Si el producto omitiera μ o ν, o usara altitud geométrica sin aclararlo, contradiría el modelo mental traído de esta herramienta. También trae la expectativa de manejo de límites del modelo (error/aviso fuera de rango), análogo al cap troposférico del producto (36.089 ft).
- **Fuente:** https://www.mathworks.com/help/aerotbx/ug/atmosisa.html (verificado vía WebFetch, junio 2026).

### Wolfram|Alpha — conversión de unidades (categoría: motor de cómputo / referencia)

- **Qué expectativa trae a este producto:** Que una magnitud física se pueda ver convertida entre sistemas (SI, imperial/US customary, métrico) sin reingresar el dato, y consultar la relación entre unidades.
- **Cómo se manifiesta:** El usuario espera obtener el valor en otro sistema de unidades como parte natural del resultado, no como un paso aparte. Esto sostiene la propuesta del producto de mostrar SI e imperial a la vez y ofrecer una sección de fórmulas/factores de conversión.
- **Fuente:** https://reference.wolfram.com/language/ref/UnitConvert.html (verificado vía WebSearch, junio 2026). No se verificó in-producto el layout exacto de "lado a lado" en la web de Wolfram|Alpha (ver Limitaciones).

### MechaniCalc / Uconeer (categoría: conversores de unidades de ingeniería)

- **Qué expectativa trae a este producto:** Disponer de **factores y tablas de conversión** consultables como referencia, incluyendo categorías de ingeniería como viscosidad y presión.
- **Cómo se manifiesta:** El ingeniero espera una sección de referencia donde el factor/fórmula de conversión sea visible y verificable (no una caja negra), exactamente el rol de la "sección de fórmulas de conversión" del producto.
- **Fuente:** https://mechanicalc.com/reference/unit-conversion-factors y https://www.katmarsoftware.com/engineering-unit-converter-uconeer.htm (verificado vía WebSearch, junio 2026; no se inspeccionó el layout en detalle).

## Patrones Recurrentes

- **Entrada altitud → cálculo de todas las magnitudes** — AviationHunt, AeroToolbox, Digital Dutch, Luiz Monteiro. La convención es que el usuario da una altitud (con selector m/ft) y el resto se computa; el flujo del producto debe respetarlo.
- **Múltiples unidades por magnitud** — Todos los competidores. La diferencia es **cómo**: simultáneo (Luiz Monteiro, AviationHunt) vs. toggle/dropdown (Digital Dutch, AeroToolbox). El producto se alinea con el patrón simultáneo SI+imperial.
- **Selector de unidad de altitud m/ft en la entrada** — Todos los competidores. Esperado y de bajo costo de aprendizaje.
- **Sección/ vista de fórmulas o constantes del modelo** — AviationHunt ("How It's Calculated"), MechaniCalc/Uconeer (tablas de factores). Esta audiencia espera poder verificar de dónde salen los números.

## Diferenciadores

- **Comparación analítico vs. interpolación lado a lado con error cuantificado** — Ningún competidor verificado muestra **dos métodos de cálculo en paralelo con su diferencia/error** (FG-3). Todos dan un único valor por magnitud. Este es el diferenciador central del producto y no tiene equivalente directo en el benchmark.
- **SI e imperial a la vez, sin toggle, para las 6 magnitudes + relativos** — Solo Luiz Monteiro y AviationHunt muestran ambos sistemas a la vez, y ninguno cubre simultáneamente magnitudes absolutas **y** relativos (θ, δ, σ, a/a₀, μ/μ₀) con doble unidad de forma integrada.
- **Cobertura completa de viscosidad dinámica y cinemática junto con los relativos** — Varios competidores omiten μ/ν o los relativos; el producto cubre el conjunto completo que un ingeniero aeronáutico espera (alineado con `atmosisa`).
- **Cliente de escritorio dedicado (no web genérica) optimizado desktop-first** — Oportunidad de layout de comparación a 1200×800 sin las restricciones de ancho y el ruido de páginas web con contenido editorial alrededor.

## Anti-patrones Detectados

- **Layout de formulario plano con muchas filas indiferenciadas** — Luiz Monteiro presenta ~28 propiedades sin jerarquía clara entre entrada y salida; el usuario escanea de más para llegar a sus 6 magnitudes. Evitar: separar visualmente entrada de resultados y priorizar las magnitudes objetivo.
- **Toggle SI/imperial que obliga a alternar para comparar** — Digital Dutch y AeroToolbox usan toggle/dropdown; impide leer ambos sistemas de un vistazo. Contradice el valor de doble unidad simultánea del producto.
- **Etiquetas recargadas / nomenclatura inflada** — AviationHunt usa rótulos como "Air Mass Density Matrix" o "Target Altitude Vector" que agregan ruido sin precisión técnica adicional. Evitar: usar la nomenclatura estándar y sobria que el ingeniero ya maneja (T, P, ρ, μ, ν, a).
- **Fragmentar cálculo, tabla y gráfico en pestañas separadas** — Digital Dutch parte la experiencia en Calculator / Table / Graphs. Para el JTBD de comparar métodos, dispersar la información entre pestañas dificulta el contraste; conviene integrar la comparación en una sola vista.

## Limitaciones del Benchmark

- **Layout exacto y comportamiento interactivo:** Las descripciones de UI provienen de conversión a markdown vía WebFetch, que aplana posiciones, agrupaciones y estados visuales. No se verificó el comportamiento dinámico real (responsividad, validaciones, mensajes de error) de ninguna calculadora.
- **AviationHunt (taxonomía de etiquetas):** Algunos rótulos reportados ("Air Mass Density Matrix", "Operational Classifications") podrían ser artefactos del marketing de la página y no etiquetas literales de los campos. A confirmar inspeccionando el producto en vivo.
- **Wolfram|Alpha (presentación lado a lado):** La búsqueda no confirmó un formato "lado a lado" SI/imperial específico en la web de Wolfram|Alpha. Se usa solo como referente de la expectativa general de conversión entre sistemas, no como evidencia de un layout concreto.
- **MechaniCalc / Uconeer:** Citados por su rol como referencia de factores de conversión; no se inspeccionó su UI en detalle. Sirven como señal de expectativa, no como patrón de UI verificado.
- **AeroToolbox (tabla/gráfico):** No se observó vista de tabla ni gráfico en esta verificación; no se puede afirmar que no existan, solo que no se confirmaron.
- **Doble método (analítico vs. interpolación):** No se encontró ningún competidor que exponga comparación entre métodos de cálculo. La afirmación de "diferenciador sin equivalente" se basa en las fuentes consultadas; podría existir alguna herramienta de nicho no indexada. A revalidar si aparece un competidor con esa función.

---

**Próximo artefacto:** Este benchmark alimenta `research-context.md` de la misma audiencia con material concreto para inferir pains, gains y JTBDs.
