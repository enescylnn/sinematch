<?php
declare(strict_types=1);

function json_response(array $data, int $status = 200) {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function ok(array $data = [], int $status = 200) {
    json_response(['ok' => true] + $data, $status);
}

function fail(string $message, int $status = 400, array $extra = []) {
    json_response(['ok' => false, 'message' => $message] + $extra, $status);
}

function input_json(): array {
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        fail('Geçersiz JSON verisi.', 400);
    }
    return $data;
}

function string_value(array $data, string $key, string $default = ''): string {
    return trim((string) ($data[$key] ?? $default));
}

function int_value(array $data, string $key, int $default = 0): int {
    return (int) ($data[$key] ?? $default);
}

function bearer_token(): ?string {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if ($header === '' && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $header = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }
    if (preg_match('/^Bearer\s+(.+)$/i', trim($header), $m)) {
        return trim($m[1]);
    }
    return null;
}

function json_array($value): array {
    if (is_array($value)) return $value;
    if (!is_string($value) || $value === '') return [];
    $decoded = json_decode($value, true);
    return is_array($decoded) ? $decoded : [];
}

function age_from_birthdate(?string $birthDate): ?int {
    if (!$birthDate) return null;
    try {
        $birth = new DateTimeImmutable($birthDate);
        return $birth->diff(new DateTimeImmutable('today'))->y;
    } catch (Throwable $e) {
        return null;
    }
}

function user_payload(array $row): array {
    $premiumUntil = $row['premium_until'] ?? null;
    $isPremium = $premiumUntil && strtotime((string) $premiumUntil) > time();

    return [
        'id' => (int) $row['id'],
        'display_name' => (string) $row['display_name'],
        'username' => (string) $row['username'],
        'email' => (string) $row['email'],
        'city' => $row['city'] ?: null,
        'avatar_url' => $row['avatar_url'] ?: null,
        'bio' => $row['bio'] ?: null,
        'age' => age_from_birthdate($row['birth_date'] ?? null),
        'is_premium' => (bool) $isPremium,
        'premium_until' => $premiumUntil,
    ];
}

function request_ip(): string {
    $forwarded = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? '';
    if ($forwarded !== '') {
        return trim(explode(',', $forwarded)[0]);
    }
    return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

function rate_limit(string $bucket): void {
    $limit = (int) cfg('security.rate_limit_per_minute', 120);
    if ($limit <= 0) return;

    $pdo = db();
    $key = hash('sha256', request_ip() . '|' . $bucket);
    $window = gmdate('Y-m-d H:i:00');

    $stmt = $pdo->prepare(
        'INSERT INTO api_rate_limits (`key_hash`, `window_start`, `hits`)
         VALUES (?, ?, 1)
         ON DUPLICATE KEY UPDATE hits = hits + 1'
    );
    $stmt->execute([$key, $window]);

    $stmt = $pdo->prepare('SELECT hits FROM api_rate_limits WHERE key_hash = ? AND window_start = ?');
    $stmt->execute([$key, $window]);
    $hits = (int) ($stmt->fetchColumn() ?: 0);

    if ($hits > $limit) {
        fail('Çok fazla istek gönderildi. Lütfen kısa bir süre sonra tekrar deneyin.', 429);
    }

    if (random_int(1, 100) === 1) {
        $pdo->exec("DELETE FROM api_rate_limits WHERE window_start < UTC_TIMESTAMP() - INTERVAL 2 DAY");
    }
}

function route_parts(): array {
    $route = trim((string) ($_GET['route'] ?? ''), '/');
    return $route === '' ? [] : explode('/', $route);
}

function method(): string {
    return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
}

function normalize_genres($value): array {
    $items = json_array($value);
    $out = [];
    foreach ($items as $item) {
        $s = trim((string) $item);
        if ($s !== '' && !in_array($s, $out, true)) {
            $out[] = mb_substr($s, 0, 60);
        }
    }
    return array_slice($out, 0, 20);
}

function compatibility_score(array $aGenres, array $bGenres): int {
    $a = array_values(array_unique(array_map('mb_strtolower', $aGenres)));
    $b = array_values(array_unique(array_map('mb_strtolower', $bGenres)));
    if (!$a || !$b) return 55;
    $intersection = count(array_intersect($a, $b));
    $union = max(1, count(array_unique(array_merge($a, $b))));
    $jaccard = $intersection / $union;
    return max(50, min(99, (int) round(58 + $jaccard * 41)));
}
