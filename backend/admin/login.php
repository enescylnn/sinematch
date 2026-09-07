<?php
declare(strict_types=1);
require_once __DIR__ . '/../app/bootstrap.php';
if (session_status() !== PHP_SESSION_ACTIVE) session_start();

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $identity = strtolower(trim((string)($_POST['identity'] ?? '')));
    $password = (string)($_POST['password'] ?? '');
    $stmt = db()->prepare('SELECT * FROM users WHERE role="admin" AND status="active" AND (LOWER(email)=? OR LOWER(username)=?) LIMIT 1');
    $stmt->execute([$identity,$identity]);
    $user = $stmt->fetch();
    if ($user && password_verify($password, (string)$user['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['sinematch_admin_id'] = (int)$user['id'];
        header('Location: index.php');
        exit;
    }
    $error = 'Giriş bilgileri hatalı.';
}
?>
<!doctype html>
<html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SineMatch Admin</title>
<style>
body{margin:0;background:#07080c;color:#fff;font:15px system-ui;display:grid;min-height:100vh;place-items:center}.box{width:min(420px,92vw);background:#11131a;border:1px solid #292c38;padding:28px;border-radius:26px}.pink{color:#ff315f}h1{margin-top:0}input{width:100%;box-sizing:border-box;background:#181b24;border:1px solid #303442;color:#fff;padding:14px;margin:7px 0 12px;border-radius:13px}button{width:100%;border:0;background:#ff315f;color:#fff;padding:14px;border-radius:13px;font-weight:800}.err{background:#4a1822;padding:12px;border-radius:12px;margin-bottom:12px}
</style></head><body><form class="box" method="post"><h1>Sine<span class="pink">Match</span> Admin</h1>
<?php if($error):?><div class="err"><?=htmlspecialchars($error)?></div><?php endif;?>
<label>E-posta veya kullanıcı adı</label><input name="identity" required autofocus>
<label>Şifre</label><input type="password" name="password" required>
<button>Giriş Yap</button></form></body></html>
