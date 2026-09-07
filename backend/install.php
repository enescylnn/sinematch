<?php
declare(strict_types=1);

// SineMatch site-demo.com.tr - preconfigured one-click installer.
// Delete this file after a successful installation.

$lockFile = __DIR__ . '/storage/installed.lock';
$configFile = __DIR__ . '/app/config.php';
$installed = is_file($lockFile);
$error = '';
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !$installed) {
    try {
        if (!is_file($configFile)) {
            throw new RuntimeException('app/config.php bulunamadi. Paketi yeniden yukleyin.');
        }
        if (!extension_loaded('pdo_mysql')) {
            throw new RuntimeException('Sunucuda PDO MySQL (pdo_mysql) etkin degil. Hosting panelinden etkinlestirin.');
        }

        $config = require $configFile;
        $db = $config['db'];
        $dsn = 'mysql:host=' . $db['host'] . ';port=' . (int)$db['port'] . ';dbname=' . $db['name'] . ';charset=' . $db['charset'];
        $pdoOptions = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        $workingPassword = $db['pass'];
        try {
            $pdo = new PDO($dsn, $db['user'], $workingPassword, $pdoOptions);
        } catch (PDOException $firstDbError) {
            // Kullanici mesajindaki \* gercek karakter de olabilir, Markdown kacisi da olabilir.
            $fallbackPassword = 'ik\\*uH8bQ$eyS4k0i';
            if ($workingPassword === $fallbackPassword) {
                throw $firstDbError;
            }
            $pdo = new PDO($dsn, $db['user'], $fallbackPassword, $pdoOptions);
            $workingPassword = $fallbackPassword;
            $config['db']['pass'] = $workingPassword;
            $configPhp = "<?php\nreturn " . var_export($config, true) . ";\n";
            if (file_put_contents($configFile, $configPhp, LOCK_EX) === false) {
                throw new RuntimeException('Calisan DB sifresi bulundu ancak config.php guncellenemedi.');
            }
        }

        $schema = file_get_contents(__DIR__ . '/schema.sql');
        if ($schema === false || trim($schema) === '') {
            throw new RuntimeException('schema.sql okunamadi.');
        }
        $statements = preg_split('/;\s*(?:\r?\n|$)/', $schema);
        foreach ($statements as $statement) {
            $statement = trim((string)$statement);
            if ($statement !== '') {
                $pdo->exec($statement);
            }
        }

        $adminEmail = 'admin@site-demo.com.tr';
        $adminUsername = 'admin';
        $adminPassword = 'admin12345678';
        $adminName = 'SineMatch Admin';
        $passwordHash = password_hash($adminPassword, PASSWORD_DEFAULT);

        $stmt = $pdo->prepare('SELECT id FROM users WHERE username=? OR email=? ORDER BY id ASC LIMIT 1');
        $stmt->execute([$adminUsername, $adminEmail]);
        $adminId = (int)($stmt->fetchColumn() ?: 0);
        if ($adminId > 0) {
            $stmt = $pdo->prepare('UPDATE users SET role="admin",email=?,username=?,password_hash=?,display_name=?,status="active",updated_at=UTC_TIMESTAMP() WHERE id=?');
            $stmt->execute([$adminEmail, $adminUsername, $passwordHash, $adminName, $adminId]);
        } else {
            $stmt = $pdo->prepare('INSERT INTO users (role,email,username,password_hash,display_name,status,created_at,updated_at) VALUES ("admin",?,?,?,?,"active",UTC_TIMESTAMP(),UTC_TIMESTAMP())');
            $stmt->execute([$adminEmail, $adminUsername, $passwordHash, $adminName]);
        }

        // Minimal content so the app is not empty before the first TMDB sync.
        $movies = [
            ['movie','Interstellar',2014,8.7,['Bilim Kurgu','Dram'],'Insanligin gelecegi icin yildizlararasi bir yolculuk.'],
            ['movie','Dune: Part Two',2024,8.6,['Bilim Kurgu','Macera'],'Arrakis uzerindeki savas buyurken Paul Atreides kaderiyle yuzlesir.'],
            ['movie','The Dark Knight',2008,9.0,['Aksiyon','Suc'],'Batman, Gothami kaosa surukleyen Joker ile karsi karsiya gelir.'],
            ['series','Dark',2017,8.7,['Bilim Kurgu','Gerilim'],'Kayip bir cocuk dort ailenin zamanla orulu sirlarini aciga cikarir.'],
        ];
        $exists = $pdo->prepare('SELECT id FROM movies WHERE title=? AND type=? LIMIT 1');
        $insert = $pdo->prepare('INSERT INTO movies (type,title,overview,release_year,genres_json,rating,popularity,created_at,updated_at) VALUES (?,?,?,?,?,?,100,UTC_TIMESTAMP(),UTC_TIMESTAMP())');
        foreach ($movies as $m) {
            $exists->execute([$m[1], $m[0]]);
            if (!$exists->fetch()) {
                $insert->execute([$m[0], $m[1], $m[5], $m[2], json_encode($m[4], JSON_UNESCAPED_UNICODE), $m[3]]);
            }
        }

        if (!is_dir(__DIR__ . '/storage') && !mkdir(__DIR__ . '/storage', 0755, true)) {
            throw new RuntimeException('storage klasoru olusturulamadi.');
        }
        if (file_put_contents($lockFile, 'installed=' . gmdate('c') . "\n", LOCK_EX) === false) {
            throw new RuntimeException('storage/installed.lock yazilamadi. Klasor izinlerini kontrol edin.');
        }

        $success = true;
        $installed = true;
    } catch (Throwable $e) {
        $error = $e->getMessage();
    }
}
?><!doctype html>
<html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SineMatch Kurulum</title>
<style>*{box-sizing:border-box}body{margin:0;background:#07080c;color:#fff;font:15px Arial,sans-serif}.wrap{max-width:760px;margin:40px auto;padding:20px}.card{background:#11131a;border:1px solid #292c38;border-radius:24px;padding:28px}h1{margin-top:0}.pink{color:#ff315f}.muted{color:#9ba0b1}.row{background:#181b24;padding:12px 14px;border-radius:12px;margin:9px 0}.ok{background:#153d31;padding:14px;border-radius:12px}.err{background:#4a1822;padding:14px;border-radius:12px}button{width:100%;margin-top:16px;border:0;border-radius:13px;background:#ff315f;color:#fff;padding:15px;font-weight:bold;font-size:16px;cursor:pointer}code{color:#ffd1db}</style></head>
<body><div class="wrap"><div class="card"><h1>Sine<span class="pink">Match</span> Kurulum</h1>
<?php if ($success): ?>
<div class="ok"><strong>Kurulum tamamlandi.</strong><br>Admin: <code>https://site-demo.com.tr/admin/</code><br>Kullanici: <code>admin</code><br>Guvenlik icin simdi <code>install.php</code> dosyasini silin.</div>
<?php elseif ($installed): ?>
<div class="ok">Sistem zaten kurulu. <code>install.php</code> dosyasini sunucudan silin.</div>
<?php else: ?>
<p class="muted">Bu paket verdigin bilgilerle onceden ayarlandi. Tek yapman gereken kurulumu baslatmak.</p>
<div class="row">Veritabani: <strong>ma</strong></div>
<div class="row">DB kullanicisi: <strong>ma</strong></div>
<div class="row">TMDB: <strong>Yapilandirildi</strong></div>
<div class="row">Admin kullanicisi: <strong>admin</strong></div>
<?php if ($error !== ''): ?><div class="err"><strong>Kurulum hatasi:</strong><br><?=htmlspecialchars($error, ENT_QUOTES, 'UTF-8')?></div><?php endif; ?>
<form method="post"><button type="submit">SineMatch Kurulumunu Baslat</button></form>
<?php endif; ?>
</div></div></body></html>
