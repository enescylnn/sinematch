<?php
declare(strict_types=1);

require_once __DIR__ . '/app/bootstrap.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if (method() === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$parts = route_parts();
$route = implode('/', $parts);
rate_limit($route === '' ? 'root' : $route);

if ($route === '' || $route === 'health') {
    ok([
        'service' => 'SineMatch API',
        'version' => '1.0.2',
        'time' => gmdate('c'),
    ]);
}

if ($route === 'auth/register' && method() === 'POST') {
    $data = input_json();
    $name = string_value($data, 'display_name');
    $username = mb_strtolower(string_value($data, 'username'));
    $email = mb_strtolower(string_value($data, 'email'));
    $password = (string)($data['password'] ?? '');
    $birthDate = string_value($data, 'birth_date');

    if ($name === '' || $username === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('Ad, kullanıcı adı ve geçerli e-posta gerekli.');
    }
    if (!preg_match('/^[a-z0-9_.]{3,30}$/i', $username)) {
        fail('Kullanıcı adı 3-30 karakter olmalı ve yalnız harf, rakam, nokta, alt çizgi içermeli.');
    }
    if (strlen($password) < 8) {
        fail('Şifre en az 8 karakter olmalı.');
    }
    $age = age_from_birthdate($birthDate);
    if ($age === null || $age < 18) {
        fail('SineMatch yalnız 18 yaş ve üzeri kullanıcılar içindir.', 422);
    }

    $pdo = db();
    $check = $pdo->prepare('SELECT id FROM users WHERE email=? OR username=? LIMIT 1');
    $check->execute([$email, $username]);
    if ($check->fetch()) fail('Bu e-posta veya kullanıcı adı zaten kullanılıyor.', 409);

    $stmt = $pdo->prepare(
        'INSERT INTO users (role,email,username,password_hash,display_name,birth_date,status,created_at,updated_at)
         VALUES ("user",?,?,?,?,?,"active",UTC_TIMESTAMP(),UTC_TIMESTAMP())'
    );
    $stmt->execute([$email, $username, password_hash($password, PASSWORD_DEFAULT), $name, $birthDate]);
    $id = (int)$pdo->lastInsertId();

    $pdo->prepare('INSERT INTO user_tastes (user_id,genres_json,looking_for_json) VALUES (?,JSON_ARRAY(),JSON_ARRAY())')->execute([$id]);

    $user = $pdo->prepare('SELECT * FROM users WHERE id=?');
    $user->execute([$id]);
    $row = $user->fetch();

    ok(['token' => issue_token($id), 'user' => user_payload($row)], 201);
}

if ($route === 'auth/login' && method() === 'POST') {
    $data = input_json();
    $identity = mb_strtolower(string_value($data, 'identity'));
    $password = (string)($data['password'] ?? '');
    if ($identity === '' || $password === '') fail('E-posta/kullanıcı adı ve şifre gerekli.');

    $stmt = db()->prepare('SELECT * FROM users WHERE (LOWER(email)=? OR LOWER(username)=?) AND status="active" LIMIT 1');
    $stmt->execute([$identity, $identity]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, (string)$user['password_hash'])) {
        fail('Giriş bilgileri hatalı.', 401);
    }
    ok(['token' => issue_token((int)$user['id']), 'user' => user_payload($user)]);
}

if ($route === 'auth/logout' && method() === 'POST') {
    $raw = bearer_token();
    current_user();
    if ($raw) {
        $stmt = db()->prepare('DELETE FROM user_tokens WHERE token_hash=?');
        $stmt->execute([hash('sha256', $raw)]);
    }
    ok(['message' => 'Çıkış yapıldı.']);
}

if ($route === 'me' && method() === 'GET') {
    $user = current_user();
    ok(['user' => user_payload($user)]);
}

if ($route === 'me' && method() === 'PUT') {
    $user = current_user();
    $data = input_json();
    $displayName = mb_substr(string_value($data, 'display_name', (string)$user['display_name']), 0, 120);
    $city = mb_substr(string_value($data, 'city', (string)($user['city'] ?? '')), 0, 120);
    $bio = mb_substr(string_value($data, 'bio', (string)($user['bio'] ?? '')), 0, 500);
    $avatar = mb_substr(string_value($data, 'avatar_url', (string)($user['avatar_url'] ?? '')), 0, 500);

    db()->prepare('UPDATE users SET display_name=?,city=?,bio=?,avatar_url=?,updated_at=UTC_TIMESTAMP() WHERE id=?')
        ->execute([$displayName, $city ?: null, $bio ?: null, $avatar ?: null, $user['id']]);
    $stmt = db()->prepare('SELECT * FROM users WHERE id=?');
    $stmt->execute([$user['id']]);
    ok(['user' => user_payload($stmt->fetch())]);
}

if ($route === 'me/tastes' && method() === 'POST') {
    $user = current_user();
    $data = input_json();
    $genres = normalize_genres($data['genres'] ?? []);
    $favoriteMovies = json_array($data['favorite_movies'] ?? []);
    $favoriteSeries = json_array($data['favorite_series'] ?? []);
    $favoriteActors = json_array($data['favorite_actors'] ?? []);
    $lookingFor = json_array($data['looking_for'] ?? []);

    $stmt = db()->prepare(
        'INSERT INTO user_tastes (user_id,genres_json,favorite_movies_json,favorite_series_json,favorite_actors_json,looking_for_json)
         VALUES (?,?,?,?,?,?)
         ON DUPLICATE KEY UPDATE genres_json=VALUES(genres_json),favorite_movies_json=VALUES(favorite_movies_json),
         favorite_series_json=VALUES(favorite_series_json),favorite_actors_json=VALUES(favorite_actors_json),
         looking_for_json=VALUES(looking_for_json),updated_at=UTC_TIMESTAMP()'
    );
    $stmt->execute([
        $user['id'],
        json_encode($genres, JSON_UNESCAPED_UNICODE),
        json_encode(array_slice($favoriteMovies, 0, 30), JSON_UNESCAPED_UNICODE),
        json_encode(array_slice($favoriteSeries, 0, 30), JSON_UNESCAPED_UNICODE),
        json_encode(array_slice($favoriteActors, 0, 30), JSON_UNESCAPED_UNICODE),
        json_encode(array_slice($lookingFor, 0, 10), JSON_UNESCAPED_UNICODE),
    ]);
    ok(['genres' => $genres]);
}

if ($route === 'movies' && method() === 'GET') {
    $search = trim((string)($_GET['search'] ?? ''));
    $genre = trim((string)($_GET['genre'] ?? ''));
    $limit = max(1, min(100, (int)($_GET['limit'] ?? 40)));
    $page = max(1, (int)($_GET['page'] ?? 1));
    $offset = ($page - 1) * $limit;

    $where = ' FROM movies WHERE 1=1';
    $sql = 'SELECT *' . $where;
    $params = [];
    if ($search !== '') {
        $sql .= ' AND (title LIKE ? OR original_title LIKE ?)';
        $params[] = '%' . $search . '%';
        $params[] = '%' . $search . '%';
    }
    if ($genre !== '') {
        $sql .= ' AND JSON_SEARCH(genres_json, "one", ?) IS NOT NULL';
        $params[] = $genre;
    }
    $countSql = 'SELECT COUNT(*)' . substr($sql, strlen('SELECT *'));
    $countStmt = db()->prepare($countSql);
    $countStmt->execute($params);
    $total = (int)$countStmt->fetchColumn();

    $sql .= ' ORDER BY popularity DESC, rating DESC, id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;

    $stmt = db()->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();
    $movies = array_map(static fn(array $m): array => [
        'id' => (int)$m['id'],
        'type' => $m['type'],
        'title' => $m['title'],
        'original_title' => $m['original_title'],
        'overview' => $m['overview'],
        'poster_url' => $m['poster_url'],
        'backdrop_url' => $m['backdrop_url'],
        'release_year' => $m['release_year'] ? (int)$m['release_year'] : null,
        'rating' => (float)$m['rating'],
        'genres' => json_array($m['genres_json']),
    ], $rows);
    ok(['movies' => $movies, 'pagination' => ['page'=>$page,'limit'=>$limit,'total'=>$total,'pages'=>(int)ceil($total/$limit)]]);
}

if (count($parts) === 2 && $parts[0] === 'movies' && ctype_digit($parts[1]) && method() === 'GET') {
    $id = (int)$parts[1];
    $stmt = db()->prepare('SELECT * FROM movies WHERE id=? LIMIT 1');
    $stmt->execute([$id]);
    $m = $stmt->fetch();
    if (!$m) fail('Film/dizi bulunamadı.', 404);

    ok(['movie' => [
        'id' => (int)$m['id'],
        'type' => $m['type'],
        'title' => $m['title'],
        'original_title' => $m['original_title'],
        'overview' => $m['overview'],
        'poster_url' => $m['poster_url'],
        'backdrop_url' => $m['backdrop_url'],
        'release_year' => $m['release_year'] ? (int)$m['release_year'] : null,
        'rating' => (float)$m['rating'],
        'genres' => json_array($m['genres_json']),
    ]]);
}

if (count($parts) === 3 && $parts[0] === 'movies' && ctype_digit($parts[1]) && $parts[2] === 'action' && method() === 'POST') {
    $user = current_user();
    $movieId = (int)$parts[1];
    $data = input_json();
    $action = string_value($data, 'action');
    if (!in_array($action, ['like','save','watched','rating'], true)) fail('Geçersiz işlem.');

    $columns = ['like' => 'liked', 'save' => 'saved', 'watched' => 'watched'];
    if ($action === 'rating') {
        $rating = (float)($data['rating'] ?? 0);
        if ($rating < 0 || $rating > 10) fail('Puan 0-10 arasında olmalı.');
        $stmt = db()->prepare(
            'INSERT INTO user_movie_actions (user_id,movie_id,rating) VALUES (?,?,?)
             ON DUPLICATE KEY UPDATE rating=VALUES(rating),updated_at=UTC_TIMESTAMP()'
        );
        $stmt->execute([$user['id'], $movieId, $rating]);
    } else {
        $column = $columns[$action];
        $sql = "INSERT INTO user_movie_actions (user_id,movie_id,{$column}) VALUES (?,?,1)
                ON DUPLICATE KEY UPDATE {$column}=IF({$column}=1,0,1),updated_at=UTC_TIMESTAMP()";
        db()->prepare($sql)->execute([$user['id'], $movieId]);
    }
    ok(['message' => 'Film tercihin güncellendi.']);
}

if ($route === 'discover' && method() === 'GET') {
    $user = current_user();
    $pdo = db();

    $tasteStmt = $pdo->prepare('SELECT genres_json FROM user_tastes WHERE user_id=?');
    $tasteStmt->execute([$user['id']]);
    $myGenres = json_array($tasteStmt->fetchColumn());

    $stmt = $pdo->prepare(
        'SELECT u.*, t.genres_json, t.favorite_movies_json
         FROM users u
         LEFT JOIN user_tastes t ON t.user_id=u.id
         WHERE u.role="user" AND u.status="active" AND u.id<>?
         AND NOT EXISTS (SELECT 1 FROM swipes s WHERE s.from_user_id=? AND s.to_user_id=u.id)
         ORDER BY u.premium_until DESC, u.created_at DESC
         LIMIT 30'
    );
    $stmt->execute([$user['id'], $user['id']]);
    $profiles = [];
    foreach ($stmt->fetchAll() as $row) {
        $theirGenres = json_array($row['genres_json']);
        $profiles[] = [
            'id' => (int)$row['id'],
            'display_name' => $row['display_name'],
            'city' => $row['city'] ?: 'Türkiye',
            'avatar_url' => $row['avatar_url'],
            'bio' => $row['bio'] ?: '',
            'age' => age_from_birthdate($row['birth_date']) ?? 25,
            'compatibility' => compatibility_score($myGenres, $theirGenres),
            'favorite_titles' => array_map('strval', array_slice(json_array($row['favorite_movies_json']), 0, 4)),
            'is_premium' => $row['premium_until'] && strtotime((string)$row['premium_until']) > time(),
        ];
    }
    ok(['profiles' => $profiles]);
}

if (count($parts) === 3 && $parts[0] === 'discover' && ctype_digit($parts[1]) && $parts[2] === 'swipe' && method() === 'POST') {
    $user = current_user();
    $targetId = (int)$parts[1];
    if ($targetId === (int)$user['id']) fail('Kendi profilin üzerinde işlem yapamazsın.');

    $data = input_json();
    $action = string_value($data, 'action');
    if (!in_array($action, ['pass','like','superlike'], true)) fail('Geçersiz swipe işlemi.');

    $pdo = db();
    $exists = $pdo->prepare('SELECT id FROM users WHERE id=? AND role="user" AND status="active" LIMIT 1');
    $exists->execute([$targetId]);
    if (!$exists->fetch()) fail('Profil bulunamadı.', 404);

    $stmt = $pdo->prepare(
        'INSERT INTO swipes (from_user_id,to_user_id,action,created_at)
         VALUES (?,?,?,UTC_TIMESTAMP())
         ON DUPLICATE KEY UPDATE action=VALUES(action),created_at=UTC_TIMESTAMP()'
    );
    $stmt->execute([$user['id'], $targetId, $action]);

    $matched = false;
    $matchId = null;
    if ($action !== 'pass') {
        $reverse = $pdo->prepare('SELECT action FROM swipes WHERE from_user_id=? AND to_user_id=? AND action IN ("like","superlike") LIMIT 1');
        $reverse->execute([$targetId, $user['id']]);
        if ($reverse->fetch()) {
            $matched = true;
            $u1 = min((int)$user['id'], $targetId);
            $u2 = max((int)$user['id'], $targetId);

            $tastes = $pdo->prepare('SELECT user_id,genres_json FROM user_tastes WHERE user_id IN (?,?)');
            $tastes->execute([$u1, $u2]);
            $map = [];
            foreach ($tastes->fetchAll() as $t) $map[(int)$t['user_id']] = json_array($t['genres_json']);
            $score = compatibility_score($map[$u1] ?? [], $map[$u2] ?? []);

            $pdo->prepare(
                'INSERT INTO matches (user1_id,user2_id,compatibility,status,created_at)
                 VALUES (?,?,?,"active",UTC_TIMESTAMP())
                 ON DUPLICATE KEY UPDATE status="active",compatibility=VALUES(compatibility)'
            )->execute([$u1, $u2, $score]);

            $find = $pdo->prepare('SELECT id FROM matches WHERE user1_id=? AND user2_id=? LIMIT 1');
            $find->execute([$u1, $u2]);
            $matchId = (int)$find->fetchColumn();

            $pdo->prepare(
                'INSERT INTO notifications (user_id,type,title,body,payload_json,created_at)
                 VALUES (?, "match", "Yeni bir eşleşmen var!", "Film zevkinize göre yeni bir eşleşme oluştu.", ?, UTC_TIMESTAMP())'
            )->execute([$targetId, json_encode(['match_id'=>$matchId])]);
        }
    }
    ok(['matched' => $matched, 'match_id' => $matchId]);
}

if ($route === 'matches' && method() === 'GET') {
    $user = current_user();
    $uid = (int)$user['id'];
    $stmt = db()->prepare(
        'SELECT m.*,
            CASE WHEN m.user1_id=? THEN u2.id ELSE u1.id END AS other_id,
            CASE WHEN m.user1_id=? THEN u2.display_name ELSE u1.display_name END AS other_name,
            CASE WHEN m.user1_id=? THEN u2.avatar_url ELSE u1.avatar_url END AS other_avatar,
            (SELECT body FROM messages mm WHERE mm.match_id=m.id ORDER BY mm.id DESC LIMIT 1) AS last_message,
            (SELECT COUNT(*) FROM messages um WHERE um.match_id=m.id AND um.sender_id<>? AND um.read_at IS NULL) AS unread
         FROM matches m
         INNER JOIN users u1 ON u1.id=m.user1_id
         INNER JOIN users u2 ON u2.id=m.user2_id
         WHERE m.status="active" AND (m.user1_id=? OR m.user2_id=?)
         ORDER BY COALESCE((SELECT MAX(created_at) FROM messages mx WHERE mx.match_id=m.id), m.created_at) DESC'
    );
    $stmt->execute([$uid,$uid,$uid,$uid,$uid,$uid]);
    $out = [];
    foreach ($stmt->fetchAll() as $m) {
        $out[] = [
            'id' => (int)$m['id'],
            'user_id' => (int)$m['other_id'],
            'display_name' => $m['other_name'],
            'avatar_url' => $m['other_avatar'],
            'compatibility' => (int)$m['compatibility'],
            'last_message' => $m['last_message'],
            'unread' => (int)$m['unread'],
        ];
    }
    ok(['matches' => $out]);
}

if (count($parts) === 3 && $parts[0] === 'matches' && ctype_digit($parts[1]) && $parts[2] === 'messages' && method() === 'GET') {
    $user = current_user();
    $matchId = (int)$parts[1];
    $uid = (int)$user['id'];

    $match = db()->prepare('SELECT * FROM matches WHERE id=? AND status="active" AND (user1_id=? OR user2_id=?) LIMIT 1');
    $match->execute([$matchId,$uid,$uid]);
    if (!$match->fetch()) fail('Eşleşme bulunamadı.', 404);

    db()->prepare('UPDATE messages SET read_at=UTC_TIMESTAMP() WHERE match_id=? AND sender_id<>? AND read_at IS NULL')->execute([$matchId,$uid]);
    $stmt = db()->prepare('SELECT id,sender_id,body,message_type,created_at FROM messages WHERE match_id=? ORDER BY id ASC LIMIT 500');
    $stmt->execute([$matchId]);
    $rows = array_map(static fn(array $m): array => [
        'id' => (int)$m['id'],
        'sender_id' => (int)$m['sender_id'],
        'body' => $m['body'],
        'message_type' => $m['message_type'],
        'created_at' => gmdate('c', strtotime($m['created_at'] . ' UTC')),
    ], $stmt->fetchAll());
    ok(['messages' => $rows]);
}

if (count($parts) === 3 && $parts[0] === 'matches' && ctype_digit($parts[1]) && $parts[2] === 'messages' && method() === 'POST') {
    $user = current_user();
    $matchId = (int)$parts[1];
    $uid = (int)$user['id'];
    $data = input_json();
    $body = trim((string)($data['body'] ?? ''));
    $type = string_value($data, 'message_type', 'text');
    if ($body === '' || mb_strlen($body) > 4000) fail('Mesaj 1-4000 karakter olmalı.');
    if (!in_array($type, ['text','movie','series'], true)) $type = 'text';

    $stmt = db()->prepare('SELECT * FROM matches WHERE id=? AND status="active" AND (user1_id=? OR user2_id=?) LIMIT 1');
    $stmt->execute([$matchId,$uid,$uid]);
    $match = $stmt->fetch();
    if (!$match) fail('Eşleşme bulunamadı.', 404);

    db()->prepare(
        'INSERT INTO messages (match_id,sender_id,body,message_type,created_at) VALUES (?,?,?,?,UTC_TIMESTAMP())'
    )->execute([$matchId,$uid,$body,$type]);
    $id = (int)db()->lastInsertId();
    $otherId = ((int)$match['user1_id'] === $uid) ? (int)$match['user2_id'] : (int)$match['user1_id'];

    db()->prepare(
        'INSERT INTO notifications (user_id,type,title,body,payload_json,created_at)
         VALUES (?,"message","Yeni mesaj",?, ?,UTC_TIMESTAMP())'
    )->execute([$otherId, mb_substr($body,0,180), json_encode(['match_id'=>$matchId])]);

    ok(['message' => [
        'id' => $id,
        'sender_id' => $uid,
        'body' => $body,
        'message_type' => $type,
        'created_at' => gmdate('c'),
    ]], 201);
}

if ($route === 'notifications' && method() === 'GET') {
    $user = current_user();
    $stmt = db()->prepare('SELECT id,type,title,body,payload_json,read_at,created_at FROM notifications WHERE user_id=? ORDER BY id DESC LIMIT 100');
    $stmt->execute([$user['id']]);
    $items = [];
    foreach ($stmt->fetchAll() as $n) {
        $items[] = [
            'id' => (int)$n['id'],
            'type' => $n['type'],
            'title' => $n['title'],
            'body' => $n['body'],
            'payload' => json_array($n['payload_json']),
            'read' => $n['read_at'] !== null,
            'created_at' => $n['created_at'],
        ];
    }
    ok(['notifications' => $items]);
}

if (count($parts) === 3 && $parts[0] === 'notifications' && ctype_digit($parts[1]) && $parts[2] === 'read' && method() === 'POST') {
    $user = current_user();
    db()->prepare('UPDATE notifications SET read_at=UTC_TIMESTAMP() WHERE id=? AND user_id=?')->execute([(int)$parts[1],$user['id']]);
    ok();
}

if ($route === 'premium/status' && method() === 'GET') {
    $user = current_user();
    $payload = user_payload($user);
    ok([
        'is_premium' => $payload['is_premium'],
        'premium_until' => $payload['premium_until'],
    ]);
}

if ($route === 'premium/receipt' && method() === 'POST') {
    $user = current_user();
    $data = input_json();
    $productId = string_value($data, 'product_id');
    $purchaseId = string_value($data, 'purchase_id');
    $source = string_value($data, 'source', 'unknown');
    $verificationData = (string)($data['verification_data'] ?? '');
    $allowed = ['sinematch_premium_1m'=>30,'sinematch_premium_6m'=>180,'sinematch_premium_12m'=>365];
    if (!isset($allowed[$productId])) fail('Geçersiz Premium ürün kimliği.');

    $mode = (string)cfg('iap.mode', 'production');
    $status = $mode === 'development' ? 'active' : 'pending';
    $days = $allowed[$productId];
    $expires = $status === 'active' ? gmdate('Y-m-d H:i:s', time() + $days * 86400) : null;

    db()->prepare(
        'INSERT INTO subscriptions (user_id,product_id,platform,external_purchase_id,status,starts_at,expires_at,receipt_hash,created_at,updated_at)
         VALUES (?,?,?,?,?,UTC_TIMESTAMP(),?,?,UTC_TIMESTAMP(),UTC_TIMESTAMP())'
    )->execute([
        $user['id'],$productId,$source,$purchaseId ?: null,$status,$expires,
        $verificationData !== '' ? hash('sha256',$verificationData) : null
    ]);

    if ($status === 'active') {
        db()->prepare('UPDATE users SET premium_until=? WHERE id=?')->execute([$expires,$user['id']]);
    }

    ok([
        'status' => $status,
        'message' => $status === 'active'
            ? 'Premium etkinleştirildi.'
            : 'Satın alma kaydedildi. Production için mağaza sunucu doğrulaması yapılandırılmalıdır.',
    ]);
}

if ($route === 'ai/recommend' && method() === 'POST') {
    $user = current_user();
    $data = input_json();
    $prompt = trim((string)($data['prompt'] ?? ''));
    if ($prompt === '' || mb_strlen($prompt) > 2000) fail('AI sorusu 1-2000 karakter olmalı.');

    $payload = user_payload($user);
    if (!$payload['is_premium']) {
        $stmt = db()->prepare('SELECT COUNT(*) FROM ai_usage WHERE user_id=? AND created_at>=UTC_DATE()');
        $stmt->execute([$user['id']]);
        if ((int)$stmt->fetchColumn() >= 5) {
            fail('Bugünkü ücretsiz SineAI hakkın doldu. Premium ile sınırsız kullanabilirsin.', 402, ['premium_required'=>true]);
        }
    }

    db()->prepare('INSERT INTO ai_usage (user_id,prompt_hash,model,created_at) VALUES (?,?,?,UTC_TIMESTAMP())')
        ->execute([$user['id'],hash('sha256',$prompt),(string)cfg('ai.model','')]);

    $apiKey = (string)cfg('ai.api_key','');
    $baseUrl = rtrim((string)cfg('ai.base_url',''), '/');
    $model = (string)cfg('ai.model','');

    if (!(bool)cfg('ai.enabled', false) || $apiKey === '' || $baseUrl === '' || $model === '') {
        $answer = 'Bu akşam bilim kurgu ve gerilim karışımı bir şey istiyorsan Arrival iyi bir başlangıç. Daha yüksek tempoda Dune: Part Two, daha karanlık ve uzun soluklu bir şey için Dark önerebilirim.';
        ok(['answer' => $answer, 'demo' => true]);
    }

    if (!function_exists('curl_init')) {
        fail('Sunucuda cURL etkin değil; AI bağlantısı kurulamadı.', 503);
    }

    $system = 'Sen SineMatch içindeki SineAI film/dizi asistanısın. Türkçe, kısa, doğal ve güvenli yanıt ver. Kullanıcının kişisel verisini varsayma. Film/dizi önerilerini nedenleriyle açıkla.';
    $body = json_encode([
        'model' => $model,
        'messages' => [
            ['role'=>'system','content'=>$system],
            ['role'=>'user','content'=>$prompt],
        ],
        'temperature' => 0.8,
    ], JSON_UNESCAPED_UNICODE);

    $ch = curl_init($baseUrl . '/chat/completions');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $apiKey,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS => $body,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 35,
    ]);
    $raw = curl_exec($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    $err = curl_error($ch);
    curl_close($ch);

    if ($raw === false || $status < 200 || $status >= 300) {
        fail('SineAI sağlayıcısına ulaşılamadı.' . ($err ? ' ' . $err : ''), 502);
    }

    $decoded = json_decode((string)$raw, true);
    $answer = $decoded['choices'][0]['message']['content'] ?? null;
    if (!is_string($answer) || trim($answer) === '') {
        fail('SineAI geçerli bir yanıt üretmedi.', 502);
    }
    ok(['answer' => trim($answer)]);
}

if ($route === 'reports' && method() === 'POST') {
    $user = current_user();
    $data = input_json();
    $targetUserId = int_value($data, 'target_user_id') ?: null;
    $matchId = int_value($data, 'match_id') ?: null;
    $reason = mb_substr(string_value($data, 'reason'), 0, 120);
    $details = mb_substr(string_value($data, 'details'), 0, 3000);
    if ($reason === '') fail('Şikayet nedeni gerekli.');

    db()->prepare(
        'INSERT INTO reports (reporter_id,target_user_id,match_id,reason,details,status,created_at)
         VALUES (?,?,?,?,?,"open",UTC_TIMESTAMP())'
    )->execute([$user['id'],$targetUserId,$matchId,$reason,$details ?: null]);
    ok(['message' => 'Şikayetin inceleme için kaydedildi.'], 201);
}

fail('Endpoint bulunamadı.', 404);
