<?php
declare(strict_types=1);

/**
 * TMDB full movie catalogue synchronizer.
 * Uses TMDB's official Daily ID Export to enumerate valid movie IDs,
 * then enriches records in small resumable batches with /movie/{id}.
 */

function tmdb_sync_ensure_schema(): void {
    $pdo = db();
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS tmdb_movie_sync_queue (
            tmdb_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
            original_title VARCHAR(255) NULL,
            popularity DECIMAL(14,4) NOT NULL DEFAULT 0,
            status ENUM("pending","synced","failed") NOT NULL DEFAULT "pending",
            attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
            last_error VARCHAR(500) NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_tmdb_queue_status (status, tmdb_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
    );
}

function tmdb_setting_get(string $key, ?string $default = null): ?string {
    $stmt = db()->prepare('SELECT `value` FROM settings WHERE `key`=? LIMIT 1');
    $stmt->execute([$key]);
    $value = $stmt->fetchColumn();
    return $value === false ? $default : (string)$value;
}

function tmdb_setting_set(string $key, ?string $value): void {
    db()->prepare(
        'INSERT INTO settings (`key`,`value`,updated_at) VALUES (?,?,UTC_TIMESTAMP())
         ON DUPLICATE KEY UPDATE `value`=VALUES(`value`),updated_at=UTC_TIMESTAMP()'
    )->execute([$key, $value]);
}

function tmdb_storage_dir(): string {
    $dir = dirname(__DIR__) . '/storage/tmdb';
    if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
        throw new RuntimeException('storage/tmdb klasörü oluşturulamadı. Plesk dosya izinlerini kontrol edin.');
    }
    return $dir;
}

function tmdb_api_key(): string {
    $key = trim((string)cfg('tmdb.api_key', ''));
    if ($key === '') {
        throw new RuntimeException('TMDB API key yapılandırılmamış.');
    }
    return $key;
}

/** @return array{status:int,body:string,error:string} */
function tmdb_http_get(string $url, int $timeout = 30): array {
    if (!function_exists('curl_init')) {
        throw new RuntimeException('Sunucuda cURL etkin değil.');
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => $timeout,
        CURLOPT_USERAGENT => 'SineMatch/1.0.2 TMDB Sync',
        CURLOPT_HTTPHEADER => ['Accept: application/json'],
    ]);
    $body = curl_exec($ch);
    $error = curl_error($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);
    return ['status'=>$status, 'body'=>$body === false ? '' : (string)$body, 'error'=>$error];
}

function tmdb_download_export(): array {
    tmdb_sync_ensure_schema();
    $dir = tmdb_storage_dir();

    // Today's export normally appears around 08:00 UTC, so try recent days automatically.
    for ($daysAgo = 0; $daysAgo <= 4; $daysAgo++) {
        $ts = time() - ($daysAgo * 86400);
        $stamp = gmdate('m_d_Y', $ts);
        $date = gmdate('Y-m-d', $ts);
        $filename = 'movie_ids_' . $stamp . '.json.gz';
        $url = 'https://files.tmdb.org/p/exports/' . $filename;
        $target = $dir . '/' . $filename;

        if (is_file($target) && filesize($target) > 1000) {
            tmdb_setting_set('tmdb_export_file', $target);
            tmdb_setting_set('tmdb_export_date', $date);
            if (tmdb_setting_get('tmdb_export_offset') === null) tmdb_setting_set('tmdb_export_offset', '0');
            return ['file'=>$target, 'date'=>$date, 'cached'=>true];
        }

        $fh = fopen($target . '.part', 'wb');
        if ($fh === false) {
            throw new RuntimeException('TMDB export dosyası için geçici dosya oluşturulamadı.');
        }
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_FILE => $fh,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_TIMEOUT => 120,
            CURLOPT_USERAGENT => 'SineMatch/1.0.2 TMDB Export',
        ]);
        $ok = curl_exec($ch);
        $status = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        fclose($fh);

        if ($ok && $status >= 200 && $status < 300 && is_file($target . '.part') && filesize($target . '.part') > 1000) {
            rename($target . '.part', $target);
            tmdb_setting_set('tmdb_export_file', $target);
            tmdb_setting_set('tmdb_export_date', $date);
            tmdb_setting_set('tmdb_export_offset', '0');
            tmdb_setting_set('tmdb_export_seed_done', '0');
            return ['file'=>$target, 'date'=>$date, 'cached'=>false];
        }
        @unlink($target . '.part');
        if ($status !== 404 && $status !== 0) {
            throw new RuntimeException('TMDB export indirilemedi. HTTP ' . $status . ($error ? ' - ' . $error : ''));
        }
    }

    throw new RuntimeException('Son günlere ait TMDB film ID export dosyası bulunamadı.');
}

function tmdb_seed_queue_batch(int $batchSize = 5000): array {
    tmdb_sync_ensure_schema();
    $file = (string)tmdb_setting_get('tmdb_export_file', '');
    if ($file === '' || !is_file($file)) {
        tmdb_download_export();
        $file = (string)tmdb_setting_get('tmdb_export_file', '');
    }
    if (!function_exists('gzopen')) {
        throw new RuntimeException('PHP zlib/gzip desteği etkin değil. Plesk PHP eklentilerinden zlib etkinleştirin.');
    }

    $offset = max(0, (int)tmdb_setting_get('tmdb_export_offset', '0'));
    $gz = gzopen($file, 'rb');
    if ($gz === false) throw new RuntimeException('TMDB export dosyası açılamadı.');
    if ($offset > 0 && gzseek($gz, $offset) !== 0) {
        gzclose($gz);
        throw new RuntimeException('TMDB export kaldığı konumdan devam ettirilemedi. Senkronu sıfırlayıp tekrar başlatın.');
    }

    $pdo = db();
    $queue = $pdo->prepare(
        'INSERT INTO tmdb_movie_sync_queue (tmdb_id,original_title,popularity,status,attempts,created_at,updated_at)
         VALUES (?,?,?,"pending",0,UTC_TIMESTAMP(),UTC_TIMESTAMP())
         ON DUPLICATE KEY UPDATE original_title=COALESCE(NULLIF(VALUES(original_title),""),original_title), popularity=GREATEST(popularity,VALUES(popularity))'
    );
    $basicMovie = $pdo->prepare(
        'INSERT INTO movies (tmdb_id,type,title,original_title,popularity,created_at,updated_at)
         VALUES (?,"movie",?,?,?,UTC_TIMESTAMP(),UTC_TIMESTAMP())
         ON DUPLICATE KEY UPDATE original_title=COALESCE(NULLIF(VALUES(original_title),""),original_title), popularity=GREATEST(popularity,VALUES(popularity)),updated_at=UTC_TIMESTAMP()'
    );

    $processed = 0;
    $inserted = 0;
    $pdo->beginTransaction();
    try {
        while ($processed < $batchSize && !gzeof($gz)) {
            $line = gzgets($gz);
            if ($line === false) break;
            $processed++;
            $row = json_decode(trim($line), true);
            if (!is_array($row)) continue;
            $id = (int)($row['id'] ?? 0);
            if ($id <= 0) continue;
            $title = trim((string)($row['original_title'] ?? $row['title'] ?? ''));
            $popularity = (float)($row['popularity'] ?? 0);
            $queue->execute([$id, $title !== '' ? mb_substr($title,0,255) : null, $popularity]);
            if ($queue->rowCount() > 0) $inserted++;
            if ($title !== '') {
                $basicMovie->execute([$id, mb_substr($title,0,220), mb_substr($title,0,220), $popularity]);
            }
        }
        $newOffset = (int)gztell($gz);
        $done = gzeof($gz);
        $pdo->commit();
        gzclose($gz);
        tmdb_setting_set('tmdb_export_offset', (string)$newOffset);
        tmdb_setting_set('tmdb_export_seed_done', $done ? '1' : '0');
        return ['processed'=>$processed, 'inserted'=>$inserted, 'offset'=>$newOffset, 'done'=>$done];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        gzclose($gz);
        throw $e;
    }
}

function tmdb_enrich_queue_batch(int $batchSize = 20): array {
    tmdb_sync_ensure_schema();
    $batchSize = max(1, min(30, $batchSize));
    $key = tmdb_api_key();
    $pdo = db();
    $stmt = $pdo->query('SELECT tmdb_id FROM tmdb_movie_sync_queue WHERE status="pending" ORDER BY tmdb_id ASC LIMIT ' . $batchSize);
    $ids = array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));
    if (!$ids) return ['processed'=>0,'synced'=>0,'failed'=>0,'rate_limited'=>false,'done'=>true];

    $upsert = $pdo->prepare(
        'INSERT INTO movies (tmdb_id,type,title,original_title,overview,poster_url,backdrop_url,release_year,genres_json,rating,popularity,created_at,updated_at)
         VALUES (?,"movie",?,?,?,?,?,?,?,?,?,UTC_TIMESTAMP(),UTC_TIMESTAMP())
         ON DUPLICATE KEY UPDATE title=VALUES(title),original_title=VALUES(original_title),overview=VALUES(overview),
         poster_url=VALUES(poster_url),backdrop_url=VALUES(backdrop_url),release_year=VALUES(release_year),genres_json=VALUES(genres_json),
         rating=VALUES(rating),popularity=VALUES(popularity),updated_at=UTC_TIMESTAMP()'
    );
    $markSynced = $pdo->prepare('UPDATE tmdb_movie_sync_queue SET status="synced",attempts=attempts+1,last_error=NULL,updated_at=UTC_TIMESTAMP() WHERE tmdb_id=?');
    $markFailed = $pdo->prepare('UPDATE tmdb_movie_sync_queue SET status="failed",attempts=attempts+1,last_error=?,updated_at=UTC_TIMESTAMP() WHERE tmdb_id=?');
    $markRetry = $pdo->prepare('UPDATE tmdb_movie_sync_queue SET attempts=attempts+1,last_error=?,updated_at=UTC_TIMESTAMP() WHERE tmdb_id=?');

    $synced = 0; $failed = 0; $processed = 0; $rateLimited = false;
    foreach ($ids as $id) {
        $url = 'https://api.themoviedb.org/3/movie/' . $id . '?api_key=' . rawurlencode($key) . '&language=tr-TR';
        $res = tmdb_http_get($url, 25);
        if ($res['status'] === 429) {
            $markRetry->execute(['TMDB rate limit (429)', $id]);
            $rateLimited = true;
            break;
        }
        $processed++;
        if ($res['status'] === 404) {
            $markFailed->execute(['TMDB kaydı artık bulunamıyor (404)', $id]);
            $failed++;
            usleep(150000);
            continue;
        }
        if ($res['status'] < 200 || $res['status'] >= 300 || $res['body'] === '') {
            $msg = 'HTTP ' . $res['status'] . ($res['error'] ? ': ' . $res['error'] : '');
            $markRetry->execute([mb_substr($msg,0,500), $id]);
            usleep(250000);
            continue;
        }
        $m = json_decode($res['body'], true);
        if (!is_array($m) || empty($m['id'])) {
            $markRetry->execute(['Geçersiz TMDB JSON yanıtı', $id]);
            continue;
        }
        $title = trim((string)($m['title'] ?? $m['original_title'] ?? ''));
        if ($title === '') {
            $markFailed->execute(['Film başlığı boş', $id]);
            $failed++;
            continue;
        }
        $date = (string)($m['release_date'] ?? '');
        $year = preg_match('/^\d{4}/', $date, $mm) ? (int)$mm[0] : null;
        $genres = [];
        foreach (($m['genres'] ?? []) as $g) {
            if (is_array($g) && !empty($g['name'])) $genres[] = (string)$g['name'];
        }
        $poster = !empty($m['poster_path']) ? 'https://image.tmdb.org/t/p/w780' . $m['poster_path'] : null;
        $backdrop = !empty($m['backdrop_path']) ? 'https://image.tmdb.org/t/p/w1280' . $m['backdrop_path'] : null;
        $upsert->execute([
            $id,
            mb_substr($title,0,220),
            mb_substr((string)($m['original_title'] ?? ''),0,220),
            (string)($m['overview'] ?? ''),
            $poster,
            $backdrop,
            $year,
            json_encode($genres, JSON_UNESCAPED_UNICODE),
            (float)($m['vote_average'] ?? 0),
            (float)($m['popularity'] ?? 0),
        ]);
        $markSynced->execute([$id]);
        $synced++;
        usleep(150000); // keep requests gentle on TMDB / shared hosting
    }

    $pending = (int)$pdo->query('SELECT COUNT(*) FROM tmdb_movie_sync_queue WHERE status="pending"')->fetchColumn();
    return ['processed'=>$processed,'synced'=>$synced,'failed'=>$failed,'rate_limited'=>$rateLimited,'done'=>$pending===0];
}

function tmdb_sync_progress(): array {
    tmdb_sync_ensure_schema();
    $pdo = db();
    $row = $pdo->query(
        'SELECT COUNT(*) total,
                SUM(status="pending") pending,
                SUM(status="synced") synced,
                SUM(status="failed") failed
         FROM tmdb_movie_sync_queue'
    )->fetch();
    return [
        'export_date' => tmdb_setting_get('tmdb_export_date'),
        'export_ready' => (string)tmdb_setting_get('tmdb_export_file','') !== '',
        'seed_done' => tmdb_setting_get('tmdb_export_seed_done','0') === '1',
        'offset' => (int)tmdb_setting_get('tmdb_export_offset','0'),
        'total' => (int)($row['total'] ?? 0),
        'pending' => (int)($row['pending'] ?? 0),
        'synced' => (int)($row['synced'] ?? 0),
        'failed' => (int)($row['failed'] ?? 0),
        'movies_in_db' => (int)$pdo->query('SELECT COUNT(*) FROM movies WHERE type="movie" AND tmdb_id IS NOT NULL')->fetchColumn(),
    ];
}

function tmdb_sync_reset(bool $deleteMovies = false): void {
    tmdb_sync_ensure_schema();
    $pdo = db();
    $pdo->exec('TRUNCATE TABLE tmdb_movie_sync_queue');
    foreach (glob(tmdb_storage_dir() . '/movie_ids_*.json.gz*') ?: [] as $file) @unlink($file);
    foreach (['tmdb_export_file','tmdb_export_date','tmdb_export_offset','tmdb_export_seed_done'] as $key) {
        $pdo->prepare('DELETE FROM settings WHERE `key`=?')->execute([$key]);
    }
    if ($deleteMovies) {
        $pdo->exec('DELETE FROM movies WHERE type="movie" AND tmdb_id IS NOT NULL');
    }
}
