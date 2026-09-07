<?php
declare(strict_types=1);
header('Content-Type: text/html; charset=utf-8');
$configFile = __DIR__ . '/app/config.php';
$config = is_file($configFile) ? require $configFile : [];
$checks = [];
$checks['PHP surumu'] = PHP_VERSION;
$checks['PHP >= 7.4'] = version_compare(PHP_VERSION, '7.4.0', '>=') ? 'OK' : 'HATA';
$checks['PDO MySQL'] = extension_loaded('pdo_mysql') ? 'OK' : 'EKSIK';
$checks['cURL (TMDB icin)'] = extension_loaded('curl') ? 'OK' : 'EKSIK';
$checks['mbstring'] = extension_loaded('mbstring') ? 'OK' : 'EKSIK';
$checks['config.php'] = is_file($configFile) ? 'OK' : 'EKSIK';
$checks['installed.lock'] = is_file(__DIR__ . '/storage/installed.lock') ? 'OK' : 'HENUZ KURULMADI';
$dbStatus = 'TEST EDILEMEDI';
if (!empty($config['db']) && extension_loaded('pdo_mysql')) {
    try {
        $db = $config['db'];
        $dsn = 'mysql:host=' . $db['host'] . ';port=' . (int)$db['port'] . ';dbname=' . $db['name'] . ';charset=' . $db['charset'];
        try {
            $pdo = new PDO($dsn, $db['user'], $db['pass'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        } catch (PDOException $e) {
            $pdo = new PDO($dsn, $db['user'], 'ik\\*uH8bQ$eyS4k0i', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        }
        $pdo->query('SELECT 1');
        $dbStatus = 'OK';
    } catch (Throwable $e) {
        $dbStatus = 'HATA: ' . $e->getMessage();
    }
}
$checks['Veritabani baglantisi'] = $dbStatus;
?><!doctype html><html lang="tr"><head><meta charset="utf-8"><title>SineMatch Diagnostik</title><style>body{background:#08090d;color:#fff;font:15px Arial;margin:30px}.box{max-width:800px;margin:auto;background:#12141b;padding:24px;border-radius:18px}div.r{padding:10px;border-bottom:1px solid #2a2d38}b{display:inline-block;min-width:220px;color:#ff5477}</style></head><body><div class="box"><h1>SineMatch Diagnostik</h1><?php foreach($checks as $k=>$v):?><div class="r"><b><?=htmlspecialchars($k,ENT_QUOTES,'UTF-8')?></b> <?=htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8')?></div><?php endforeach;?><p>Kurulum tamamlandiktan sonra guvenlik icin <strong>diagnostics.php</strong> dosyasini sil.</p></div></body></html>
