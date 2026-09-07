<?php
declare(strict_types=1);

function issue_token(int $userId): string {
    $raw = bin2hex(random_bytes(32));
    $hash = hash('sha256', $raw);
    $days = max(1, (int) cfg('security.token_ttl_days', 30));

    $stmt = db()->prepare(
        'INSERT INTO user_tokens (user_id, token_hash, expires_at, created_at)
         VALUES (?, ?, UTC_TIMESTAMP() + INTERVAL ? DAY, UTC_TIMESTAMP())'
    );
    $stmt->execute([$userId, $hash, $days]);
    return $raw;
}

function current_user(bool $required = true): ?array {
    $raw = bearer_token();
    if (!$raw) {
        if ($required) fail('Oturum gerekli.', 401);
        return null;
    }

    $hash = hash('sha256', $raw);
    $stmt = db()->prepare(
        'SELECT u.*
         FROM user_tokens t
         INNER JOIN users u ON u.id = t.user_id
         WHERE t.token_hash = ? AND t.expires_at > UTC_TIMESTAMP() AND u.status = "active"
         LIMIT 1'
    );
    $stmt->execute([$hash]);
    $user = $stmt->fetch();

    if (!$user) {
        if ($required) fail('Oturum süresi dolmuş veya geçersiz.', 401);
        return null;
    }
    return $user;
}

function require_admin_session(): array {
    if (session_status() !== PHP_SESSION_ACTIVE) {
        session_start();
    }
    $id = (int) ($_SESSION['sinematch_admin_id'] ?? 0);
    if ($id <= 0) {
        header('Location: login.php');
        exit;
    }
    $stmt = db()->prepare('SELECT * FROM users WHERE id = ? AND role = "admin" AND status = "active" LIMIT 1');
    $stmt->execute([$id]);
    $user = $stmt->fetch();
    if (!$user) {
        session_destroy();
        header('Location: login.php');
        exit;
    }
    return $user;
}
