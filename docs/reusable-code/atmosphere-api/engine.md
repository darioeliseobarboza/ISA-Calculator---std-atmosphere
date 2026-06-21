# Reusable Code - Domain Engine - atmosphere-api

## Overview

Package `internal/calculation` holds the ISA analytical engine (story S-004):
the exact ISA 1976 constants and the troposphere solver. These are pure,
stateless and reused by future calculation features (FG-3 interpolation builds
its reference grid on top of the same analytical engine and constants).

## calculation ISA constants

**Location:** `internal/calculation/constants.go`
**Description:** The exact ISA 1976 / ICAO base constants (ADR-005, verbatim) plus the derived constants computed at runtime (never hardcoded rounded). Immutable package-level values.

**Definition:**
```go
// Base (exact) constants:
const (
    RStar       = 8.31432    // J/(mol·K)
    M0          = 0.0289644  // kg/mol
    T0          = 288.15     // K
    P0          = 101325.0   // Pa
    LapseRate   = -0.0065    // K/m
    G0          = 9.80665    // m/s²
    Gamma       = 1.4        // -
    Beta        = 1.458e-6   // kg/(m·s·√K)
    SutherlandS = 110.4      // K
)

// Derived at runtime:
var (
    R                = RStar / M0                       // ≈ 287.0529 J/(kg·K)
    Rho0             = P0 / (R * T0)                     // ≈ 1.2250 kg/m³
    A0               = math.Sqrt(Gamma * R * T0)         // ≈ 340.294 m/s
    Mu0              = Beta * math.Pow(T0, 1.5) / (T0+SutherlandS) // ≈ 1.7894e-5 Pa·s
    PressureExponent = G0 / (R * math.Abs(LapseRate))    // ≈ 5.2559 (dimensionless)
)
```

---

## calculation.Troposphere

**Location:** `internal/calculation/troposphere.go`
**Description:** Pure analytical ISA solver for the gradient layer (0–36089 ft). Given a geopotential altitude in feet (the canonical unit, ADR-002), returns the absolute magnitudes in SI and the dimensionless relative ratios. The temperature model works in SI (altitude converted ft→m); pressure/density use the temperature ratio and the dimensionless exponent. No internal rounding (ADR-005). Range validation is the caller's responsibility.

**Signature:**
```go
func Troposphere(altitudeFt float64) Result
```

Where `Result` (in `calculation.go`) groups: `Temperature` (K), `Pressure` (Pa), `Density` (kg/m³), `DynamicViscosity` (Pa·s), `KinematicViscosity` (m²/s), `SpeedOfSound` (m/s), and the relatives `Theta`, `Delta`, `Sigma`, `SpeedOfSoundRatio`, `ViscosityRatio`.

**Usage:**
```go
r := calculation.Troposphere(16404) // ≈ 5000 m
// r.Temperature ≈ 255.65 K, r.Theta ≈ 0.887, ...
```
