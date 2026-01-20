# Database Package

I wanted to take more control over my database connections while also **learning SQL properly**. ORMs are convenient, but they hide what's actually happening. I wanted to understand the queries I'm writing.

After some research, I found [SQLC](https://sqlc.dev/) — it generates Go code from SQL, so you write real SQL and get type-safe functions. No magic, no hidden queries, just SQL you understand and control.

I made this package to make it easy to start new Go projects. Every time I start a new project, I just copy this folder and I'm ready to go. It's production-ready and works with SQLite, PostgreSQL, and MySQL.

**If you find this useful, feel free to use it too!**

> ⚠️ This is a **downloadable example**, not a standalone library. The schema and queries here are from my actual project. Look at how I structured things and adapt it to your needs.

---

## How It Works

1. **You write SQL** in `schema.sql` (tables) and `queries.sql` (queries)
2. **SQLC generates Go code** — type-safe structs and functions
3. **You use the generated code** via `database.Get().Q.YourQuery()`

That's it. No learning curve, just SQL you already know.

---

## Quick Start

### 1. Initialize in your main.go

```go
package main

import "your-project/database"

func main() {
    // Call this once at startup
    database.MustInit(database.Config{
        Driver:   "sqlite3",
        DSN:      "myapp.db",
        LogLevel: "info",
    })
    defer database.Close()
    
    // Your app code...
}
```

### 2. Use in your code

```go
ctx := context.Background()
db := database.Get()

// All your queries are here, type-safe!
user, err := db.Q.GetUserByTelegramID(ctx, 12345)
users, err := db.Q.GetTopUsersByBalance(ctx, 50)

// Create/Update
newUser, err := db.Q.CreateUser(ctx, database.CreateUserParams{
    TelegramID: 12345,
    FirstName:  "John",
    // ...
})
```

### 3. Transactions

```go
err := database.Get().Transaction(ctx, func(q *database.Queries) error {
    // Everything here is atomic
    user, err := q.CreateUser(ctx, params)
    if err != nil {
        return err // Auto rollback
    }
    _, err = q.CreateUserGroup(ctx, ugParams)
    return err // Commit if nil, rollback if error
})
```

---

## Project Structure

```
database/
│
├── sqlc.yaml                    # SQLC configuration
├── schema.sql                   # Your table definitions (embedded into binary)
├── queries.sql                  # Your SQL queries
│
├── init.go                      # SQLite init (active)
├── init_postgresql.go.example   # PostgreSQL template
├── init_mysql.go.example        # MySQL template
│
├── db.go                        # [GENERATED] Don't edit
├── models.go                    # [GENERATED] Go structs from your tables
├── queries.sql.go               # [GENERATED] Query functions
│
└── README.md                    # You're here
```

**What you edit:** `schema.sql`, `queries.sql`, `init.go`  
**What SQLC generates:** `db.go`, `models.go`, `queries.sql.go`

---

## Adding New Queries

1. Add your SQL to `queries.sql`:
```sql
-- name: GetActiveUsers :many
SELECT * FROM users WHERE status = 'active';

-- name: DeleteOldRecords :exec
DELETE FROM logs WHERE created_at < ?;
```

2. Regenerate:
```bash
cd database
sqlc generate
```

3. Use in code:
```go
users, err := db.Q.GetActiveUsers(ctx)
err := db.Q.DeleteOldRecords(ctx, cutoffDate)
```

For more query patterns, check the [official SQLC docs](https://docs.sqlc.dev/).

---

## Switching Databases

I've included templates for PostgreSQL and MySQL. To switch:

1. **Copy the template** to `init.go`:
   ```bash
   cp init_postgresql.go.example init.go
   # or
   cp init_mysql.go.example init.go
   ```

2. **Update sqlc.yaml**:
   ```yaml
   engine: "postgresql"  # or "mysql"
   ```

3. **Adjust schema.sql** for your database's syntax

4. **Regenerate**:
   ```bash
   sqlc generate
   go mod tidy
   ```

### Driver Packages

| Database   | Package | Install |
|------------|---------|---------|
| SQLite | `github.com/mattn/go-sqlite3` | `go get github.com/mattn/go-sqlite3` |
| PostgreSQL | `github.com/lib/pq` | `go get github.com/lib/pq` |
| MySQL | `github.com/go-sql-driver/mysql` | `go get github.com/go-sql-driver/mysql` |

### Connection Strings

```bash
# SQLite
myapp.db
:memory:

# PostgreSQL
postgres://user:pass@localhost:5432/dbname?sslmode=disable

# MySQL
user:pass@tcp(localhost:3306)/dbname?parseTime=true
```

---

## Starting a New Project

1. Copy this `database/` folder to your new project
2. Edit `schema.sql` with your tables
3. Edit `queries.sql` with your queries
4. Run `sqlc generate`
5. Update DSN in your `main.go`
6. Done!

---

## My Example Files

The `schema.sql` and `queries.sql` in this repo are from my Telegram bot project. You'll see:

- **Users, Groups, UserGroup tables** — typical many-to-many relationship
- **Upsert queries** — insert or update in one call
- **Aggregate queries** — SUM, COUNT, JOINs for stats

Feel free to use these as reference for how to structure your own queries.

---

## Links

- [SQLC Documentation](https://docs.sqlc.dev/)
- [SQLC Playground](https://play.sqlc.dev/) — try queries online
- [Query Annotations](https://docs.sqlc.dev/en/latest/reference/query-annotations.html) — `:one`, `:many`, `:exec`, etc.
