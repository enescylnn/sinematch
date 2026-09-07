<?php
declare(strict_types=1);
require_once __DIR__ . '/../app/bootstrap.php';
require_once __DIR__ . '/../app/tmdb_sync.php';
require_admin_session();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $action = (string)($_POST['action'] ?? $_GET['action'] ?? 'progress');
    if ($action === 'prepare') {
        $result = tmdb_download_export();
        echo json_encode(['ok'=>true,'result'=>$result,'progress'=>tmdb_sync_progress()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES); exit;
    }
    if ($action === 'seed') {
        $result = tmdb_seed_queue_batch(5000);
        echo json_encode(['ok'=>true,'result'=>$result,'progress'=>tmdb_sync_progress()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES); exit;
    }
    if ($action === 'enrich') {
        $result = tmdb_enrich_queue_batch(20);
        echo json_encode(['ok'=>true,'result'=>$result,'progress'=>tmdb_sync_progress()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES); exit;
    }
    if ($action === 'reset') {
        tmdb_sync_reset(!empty($_POST['delete_movies']));
        echo json_encode(['ok'=>true,'progress'=>tmdb_sync_progress()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES); exit;
    }
    echo json_encode(['ok'=>true,'progress'=>tmdb_sync_progress()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['ok'=>false,'message'=>$e->getMessage()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
}
