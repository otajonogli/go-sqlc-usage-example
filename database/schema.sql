-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    telegram_id INTEGER NOT NULL UNIQUE,
    first_name TEXT NOT NULL DEFAULT '',
    username TEXT DEFAULT '',
    balance_game REAL DEFAULT 0,
    balance_chats REAL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    language TEXT NOT NULL DEFAULT 'en',
    refer_from_id INTEGER,
    last_streak_claim_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Groups table
CREATE TABLE IF NOT EXISTS groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    balance REAL DEFAULT 0,
    telegram_id INTEGER NOT NULL UNIQUE,
    title TEXT DEFAULT '',
    url TEXT DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- User-Group relationship table
CREATE TABLE IF NOT EXISTS user_group (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_telegram_id INTEGER NOT NULL,
    group_telegram_id INTEGER NOT NULL,
    balance REAL DEFAULT 0,
    UNIQUE(user_telegram_id, group_telegram_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_telegram_id ON users(telegram_id);
CREATE INDEX IF NOT EXISTS idx_groups_telegram_id ON groups(telegram_id);
CREATE INDEX IF NOT EXISTS idx_user_group_user ON user_group(user_telegram_id);
CREATE INDEX IF NOT EXISTS idx_user_group_group ON user_group(group_telegram_id);
