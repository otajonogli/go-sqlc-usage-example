-- =====================
-- USER QUERIES
-- =====================

-- name: GetUserByTelegramID :one
SELECT * FROM users WHERE telegram_id = ? LIMIT 1;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = ? LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
    telegram_id, first_name, username, status, language, refer_from_id
) VALUES (?, ?, ?, ?, ?, ?)
RETURNING *;

-- name: UpdateUser :one
UPDATE users 
SET first_name = ?, username = ?, updated_at = CURRENT_TIMESTAMP
WHERE telegram_id = ?
RETURNING *;

-- name: UpdateUserBalanceChats :exec
UPDATE users 
SET balance_chats = ?, updated_at = CURRENT_TIMESTAMP
WHERE telegram_id = ?;

-- name: GetTopUsersByBalance :many
SELECT * FROM users 
ORDER BY (balance_game + balance_chats) DESC 
LIMIT ?;

-- name: GetUserPosition :one
SELECT COUNT(*) + 1 AS position FROM users 
WHERE (balance_game + balance_chats) > ?;

-- name: UpsertUser :one
INSERT INTO users (telegram_id, first_name, username, status, language)
VALUES (?, ?, ?, 'active', 'en')
ON CONFLICT(telegram_id) DO UPDATE SET
    first_name = CASE WHEN excluded.first_name != '' THEN excluded.first_name ELSE users.first_name END,
    username = CASE WHEN excluded.username != '' THEN excluded.username ELSE users.username END,
    updated_at = CURRENT_TIMESTAMP
RETURNING *;

-- =====================
-- GROUP QUERIES  
-- =====================

-- name: GetGroupByTelegramID :one
SELECT * FROM groups WHERE telegram_id = ? LIMIT 1;

-- name: CreateGroup :one
INSERT INTO groups (telegram_id, title)
VALUES (?, ?)
RETURNING *;

-- name: UpsertGroup :one
INSERT INTO groups (telegram_id, title)
VALUES (?, ?)
ON CONFLICT(telegram_id) DO UPDATE SET
    title = CASE WHEN excluded.title != '' THEN excluded.title ELSE groups.title END,
    updated_at = CURRENT_TIMESTAMP
RETURNING *;

-- =====================
-- USER-GROUP QUERIES
-- =====================

-- name: GetUserGroup :one
SELECT * FROM user_group 
WHERE user_telegram_id = ? AND group_telegram_id = ? 
LIMIT 1;

-- name: CreateUserGroup :one
INSERT INTO user_group (user_telegram_id, group_telegram_id, balance)
VALUES (?, ?, 0)
RETURNING *;

-- name: GetOrCreateUserGroup :one
INSERT INTO user_group (user_telegram_id, group_telegram_id, balance)
VALUES (?, ?, 0)
ON CONFLICT(user_telegram_id, group_telegram_id) DO UPDATE SET
    balance = user_group.balance
RETURNING *;

-- name: UpdateUserGroupBalance :exec
UPDATE user_group 
SET balance = ? 
WHERE user_telegram_id = ? AND group_telegram_id = ?;

-- name: AddToUserGroupBalance :exec
UPDATE user_group 
SET balance = balance + ? 
WHERE user_telegram_id = ? AND group_telegram_id = ?;

-- name: GetTotalUserBalance :one
SELECT COALESCE(SUM(balance), 0) AS total FROM user_group 
WHERE user_telegram_id = ?;

-- name: GetTotalGroupBalance :one
SELECT COALESCE(SUM(balance), 0) AS total FROM user_group 
WHERE group_telegram_id = ?;

-- =====================
-- STATS QUERIES
-- =====================

-- name: GetTopUsersInGroup :many
SELECT 
    u.first_name,
    u.username,
    ug.balance
FROM user_group ug
LEFT JOIN users u ON u.telegram_id = ug.user_telegram_id
WHERE ug.group_telegram_id = ?
ORDER BY ug.balance DESC
LIMIT 10;

-- name: GetTopGroupsForUser :many
SELECT 
    g.title,
    ug.balance
FROM user_group ug
LEFT JOIN groups g ON g.telegram_id = ug.group_telegram_id
WHERE ug.user_telegram_id = ?
ORDER BY ug.balance DESC
LIMIT 10;
