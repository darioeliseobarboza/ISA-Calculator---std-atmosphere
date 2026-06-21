// Package calculation is the ISA analytical engine of atmosphere-api: the exact
// ISA 1976 constants, the troposphere model (0–36089 ft) and the analytical
// formulas, plus the application Service and HTTP Handler that expose them at
// POST /v1/calculate.
//
// All computation is float64 with no internal rounding (ADR-005): rounding is a
// presentation concern owned by the frontend (S-005), not by the API.
package calculation

import "math"

// Base constants — the exact ISA 1976 / ICAO values (ADR-005, verbatim). They
// MUST NOT be replaced by newer physical values, to stay coherent with the ISA
// and the UTN reference table.
const (
	// RStar is the universal gas constant R* in J/(mol·K).
	RStar = 8.31432
	// M0 is the sea-level molar mass of air in kg/mol.
	M0 = 0.0289644
	// T0 is the sea-level standard temperature in K.
	T0 = 288.15
	// P0 is the sea-level standard pressure in Pa.
	P0 = 101325.0
	// LapseRate is the troposphere temperature gradient L in K/m.
	LapseRate = -0.0065
	// G0 is the standard gravitational acceleration in m/s².
	G0 = 9.80665
	// Gamma is the ratio of specific heats for air (dimensionless).
	Gamma = 1.4
	// Beta is Sutherland's constant β in kg/(m·s·√K).
	Beta = 1.458e-6
	// SutherlandS is Sutherland's temperature S in K.
	SutherlandS = 110.4
)

// Derived constants — computed at runtime from the base constants (ADR-005:
// never hardcode rounded values). Package-level vars are evaluated in
// dependency order by the Go runtime; these are immutable (the only global
// state allowed by the _base convention).
var (
	// R is the specific gas constant for air, R = R*/M0, in J/(kg·K).
	R = RStar / M0
	// Rho0 is the sea-level standard density, ρ₀ = P0/(R·T0), in kg/m³.
	Rho0 = P0 / (R * T0)
	// A0 is the sea-level speed of sound, a₀ = √(γ·R·T0), in m/s.
	A0 = math.Sqrt(Gamma * R * T0)
	// Mu0 is the sea-level dynamic viscosity (Sutherland), μ₀ = β·T0^1.5/(T0+S),
	// in Pa·s.
	Mu0 = Beta * math.Pow(T0, 1.5) / (T0 + SutherlandS)
	// PressureExponent is the troposphere pressure exponent n = g0/(R·|L|),
	// dimensionless (≈ 5.2559). It uses L and R in SI; being an exponent over a
	// temperature ratio, it does not change with the altitude unit.
	PressureExponent = G0 / (R * math.Abs(LapseRate))
)
