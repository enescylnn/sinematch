<?php
declare(strict_types=1);

date_default_timezone_set('UTC');

$configFile = __DIR__ . '/config.php';
$installLock = dirname(__DIR__) . '/storage/installed.lock';
if (!is_file($configFile)) {
    http_response_code(503);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'ok' => false,
        'message' => 'SineMatch backend kurulmamış. install.php adresini açın.',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$config = require $configFile;

if (!is_file($installLock)) {
    http_response_code(503);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'ok' => false,
        'message' => 'SineMatch kurulumu tamamlanmamis. /install.php adresini acin.',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function cfg(string $path, $default = null) {
    global $config;
    $value = $config;
    foreach (explode('.', $path) as $segment) {
        if (!is_array($value) || !array_key_exists($segment, $value)) {
            return $default;
        }
        $value = $value[$segment];
    }
    return $value;
}

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/auth.php';
