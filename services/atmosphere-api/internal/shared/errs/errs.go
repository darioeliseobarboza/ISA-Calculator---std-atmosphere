// Package errs holds the typed domain errors of atmosphere-api and the public
// error codes the service exposes at the HTTP boundary.
//
// Per ADR-001 the POST /v1/calculate contract returns camelCase error codes
// (outOfRange | invalidInput | invalidStep) — deliberately NOT the generic
// SCREAMING_SNAKE codes of the shared error-handling convention. Changing a
// Code here is a breaking change to the public contract.
//
// This package lives under internal/shared and must NOT import internal/http
// or internal/calculation, so it stays free of import cycles.
package errs

import (
	"fmt"
	"net/http"
)

// Public error codes of the POST /v1/calculate contract (ADR-001).
const (
	// CodeOutOfRange is emitted when the geopotential altitude falls outside
	// 0–36089 ft after normalization.
	CodeOutOfRange = "outOfRange"
	// CodeInvalidInput is emitted when the request body is not parseable, the
	// required field is missing, or the value is not a usable number.
	CodeInvalidInput = "invalidInput"
	// CodeInvalidStep is reserved for FG-3 (table step validation). It is part
	// of the OpenAPI enum but no active constructor emits it in FG-2.
	CodeInvalidStep = "invalidStep"
)

// Error is a typed domain error carrying the public Code reported to clients,
// a human Message, and an optional wrapped cause. The HTTP boundary reads Code
// and Status() to build the canonical { "error": { code, message } } envelope;
// handlers never set status codes by hand.
type Error struct {
	// Code is the public, contract-level error code (camelCase, ADR-001).
	Code string
	// Message is the human-readable explanation surfaced to the client.
	Message string
	// cause is the optional underlying error, exposed via Unwrap.
	cause error
}

// Error implements the error interface.
func (e *Error) Error() string {
	if e.cause != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.cause)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Unwrap exposes the wrapped cause so errors.Is/As can traverse the chain.
func (e *Error) Unwrap() error { return e.cause }

// Wrap attaches an underlying cause and returns the receiver for fluent use.
func (e *Error) Wrap(cause error) *Error {
	e.cause = cause
	return e
}

// Status returns the HTTP status for this error. Both FG-2 domain codes map to
// 400; the boundary maps any non-*Error to 500.
func (e *Error) Status() int {
	switch e.Code {
	case CodeOutOfRange, CodeInvalidInput, CodeInvalidStep:
		return http.StatusBadRequest
	default:
		return http.StatusInternalServerError
	}
}

// NewOutOfRange builds an *Error with code "outOfRange" (HTTP 400): the
// altitude is outside the valid 0–36089 ft band.
func NewOutOfRange(msg string) *Error {
	return &Error{Code: CodeOutOfRange, Message: msg}
}

// NewInvalidInput builds an *Error with code "invalidInput" (HTTP 400): the
// input could not be parsed into a usable calculation request.
func NewInvalidInput(msg string) *Error {
	return &Error{Code: CodeInvalidInput, Message: msg}
}
