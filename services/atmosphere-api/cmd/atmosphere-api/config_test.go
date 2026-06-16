package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoadConfig(t *testing.T) {
	tests := []struct {
		name    string
		env     map[string]string
		want    Config
		wantErr bool
		errMsg  string
	}{
		{
			// TS-8: defaults applied when no env vars are present.
			name: "defaults applied",
			env: map[string]string{
				"ENV": "development",
			},
			want: Config{
				Env:                "development",
				HTTPAddr:           ":8080",
				LogDir:             "./logs",
				LogDebug:           false,
				CORSAllowedOrigins: nil,
			},
			wantErr: false,
		},
		{
			// TS-9: fail-fast in production without CORS_ALLOWED_ORIGINS.
			name: "fail-fast in production without CORS",
			env: map[string]string{
				"ENV": "production",
			},
			wantErr: true,
			errMsg:  "CORS_ALLOWED_ORIGINS",
		},
		{
			// TS-10: CSV parsing with trimming.
			name: "CSV origins parsed and trimmed",
			env: map[string]string{
				"ENV":                  "development",
				"CORS_ALLOWED_ORIGINS": "https://a.com, https://b.com",
			},
			want: Config{
				Env:                "development",
				HTTPAddr:           ":8080",
				LogDir:             "./logs",
				LogDebug:           false,
				CORSAllowedOrigins: []string{"https://a.com", "https://b.com"},
			},
			wantErr: false,
		},
		{
			// TS-11: explicit HTTP_ADDR respected.
			name: "explicit HTTP_ADDR respected",
			env: map[string]string{
				"ENV":       "development",
				"HTTP_ADDR": ":9090",
			},
			want: Config{
				Env:                "development",
				HTTPAddr:           ":9090",
				LogDir:             "./logs",
				LogDebug:           false,
				CORSAllowedOrigins: nil,
			},
			wantErr: false,
		},
		{
			name: "production with CORS succeeds",
			env: map[string]string{
				"ENV":                  "production",
				"HTTP_ADDR":            ":8080",
				"CORS_ALLOWED_ORIGINS": "https://app.example.com",
			},
			want: Config{
				Env:                "production",
				HTTPAddr:           ":8080",
				LogDir:             "./logs",
				LogDebug:           false,
				CORSAllowedOrigins: []string{"https://app.example.com"},
			},
			wantErr: false,
		},
		{
			name: "LOG_DEBUG=true enables debug",
			env: map[string]string{
				"ENV":       "development",
				"LOG_DEBUG": "true",
				"LOG_DIR":   "/tmp/logs",
			},
			want: Config{
				Env:                "development",
				HTTPAddr:           ":8080",
				LogDir:             "/tmp/logs",
				LogDebug:           true,
				CORSAllowedOrigins: nil,
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Isolate this test from the host environment: every key the loader
			// reads is set explicitly (t.Setenv auto-restores on cleanup).
			for _, key := range []string{"ENV", "HTTP_ADDR", "LOG_DIR", "LOG_DEBUG", "CORS_ALLOWED_ORIGINS"} {
				t.Setenv(key, "")
			}
			for k, v := range tt.env {
				t.Setenv(k, v)
			}

			cfg, err := loadConfig()

			if tt.wantErr {
				require.Error(t, err)
				if tt.errMsg != "" {
					assert.Contains(t, err.Error(), tt.errMsg)
				}
				assert.Equal(t, Config{}, cfg)
				return
			}

			require.NoError(t, err)
			assert.Equal(t, tt.want, cfg)
		})
	}
}

func TestSplitCSV(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want []string
	}{
		{name: "empty string yields nil", in: "", want: nil},
		{name: "whitespace only yields nil", in: "   ", want: nil},
		{name: "single value", in: "https://a.com", want: []string{"https://a.com"}},
		{name: "multiple with spaces trimmed", in: " https://a.com , https://b.com ", want: []string{"https://a.com", "https://b.com"}},
		{name: "skips empty segments", in: "https://a.com,,https://b.com", want: []string{"https://a.com", "https://b.com"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, splitCSV(tt.in))
		})
	}
}
