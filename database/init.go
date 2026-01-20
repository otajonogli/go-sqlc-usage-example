// ============================================================================
// SQLite Init (Default) - This is the active init file
// ============================================================================
//
// DRIVER: github.com/mattn/go-sqlite3 (requires CGO)
//   For CGO-free alternative: modernc.org/sqlite
//
// DSN FORMAT:
//   file.db              - Regular file
//   :memory:             - In-memory database
//   file.db?mode=ro      - Read-only
//   file.db?_journal=WAL - Write-Ahead Logging (better concurrency)
//
// TO SWITCH DATABASE:
//   See init_postgresql.go.example or init_mysql.go.example
// ============================================================================

package database

import (
	"context"
	"database/sql"
	_ "embed"
	"fmt"
	"log"
	"sync"

	_ "github.com/mattn/go-sqlite3" // SQLite driver (CGO required)
	// Alternative CGO-free driver:
	// _ "modernc.org/sqlite"
)

//go:embed schema.sql
var schemaSQL string

// DB holds the database connection and query interface
type DB struct {
	Conn *sql.DB
	Q    *Queries
}

// Global instance
var (
	instance *DB
	once     sync.Once
)

// Config holds database configuration
type Config struct {
	Driver   string // "sqlite3" or "sqlite" (for modernc)
	DSN      string // Database file path or :memory:
	LogLevel string // "silent", "error", "warn", "info"
}

// DefaultConfig returns default SQLite configuration
func DefaultConfig() Config {
	return Config{
		Driver:   "sqlite3",
		DSN:      "app.db",
		LogLevel: "error",
	}
}

// Init initializes the database with the given configuration
func Init(cfg Config) (*DB, error) {
	var initErr error

	once.Do(func() {
		driver := cfg.Driver
		if driver == "" {
			driver = "sqlite3"
		}

		conn, err := sql.Open(driver, cfg.DSN)
		if err != nil {
			initErr = fmt.Errorf("failed to open database: %w", err)
			return
		}

		// Test connection
		if err := conn.Ping(); err != nil {
			initErr = fmt.Errorf("failed to ping database: %w", err)
			return
		}

		// Run schema migrations
		if _, err := conn.ExecContext(context.Background(), schemaSQL); err != nil {
			initErr = fmt.Errorf("failed to run schema migrations: %w", err)
			return
		}

		instance = &DB{
			Conn: conn,
			Q:    New(conn),
		}

		if cfg.LogLevel != "silent" {
			log.Println("SQLite connected successfully!")
		}
	})

	if initErr != nil {
		return nil, initErr
	}

	return instance, nil
}

// MustInit initializes the database and panics on error
func MustInit(cfg Config) *DB {
	db, err := Init(cfg)
	if err != nil {
		log.Fatalf("Database initialization failed: %v", err)
	}
	return db
}

// Get returns the global database instance
func Get() *DB {
	if instance == nil {
		log.Fatal("Database not initialized. Call Init() first.")
	}
	return instance
}

// Close closes the database connection
func Close() error {
	if instance != nil && instance.Conn != nil {
		return instance.Conn.Close()
	}
	return nil
}

// Transaction executes a function within a database transaction
func (db *DB) Transaction(ctx context.Context, fn func(*Queries) error) error {
	tx, err := db.Conn.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	if err := fn(db.Q.WithTx(tx)); err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("tx error: %v, rollback error: %w", err, rbErr)
		}
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}
