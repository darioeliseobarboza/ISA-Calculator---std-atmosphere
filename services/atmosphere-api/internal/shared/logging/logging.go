// Package logging builds the single structured logger for atmosphere-api.
//
// There is one logger per service, constructed in main and injected as a
// dependency. There is no global logger and no use of log.Print / fmt.Println
// in service code. Per-request correlation is carried via key-value args
// (see RequestArgs in the http package), since slogx has no per-context child
// logger.
package logging

import (
	"github.com/darioeliseobarboza/slogx"
)

// New constructs the service logger over slogx. info/warn/error levels are
// always enabled; debug is gated by the debug flag. Log files are written
// under dir (slogx also writes to the console). The caller owns the returned
// logger and must call Close (typically deferred in main).
func New(dir string, debug bool) (*slogx.Logger, error) {
	cfg := slogx.DefaultConfig()
	cfg.Dir = dir
	cfg.InfoEnabled = true
	cfg.WarnEnabled = true
	cfg.ErrorEnabled = true
	cfg.DebugEnabled = debug
	return slogx.New(cfg)
}
