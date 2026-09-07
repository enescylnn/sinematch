<?php
declare(strict_types=1);
require_once __DIR__ . '/../app/bootstrap.php';
$admin = require_admin_session();
$pdo = db();

$notice = '';
$error = '';
$action = $_POST['action'] ?? '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'set_user_status') {
    $id = (int)($_POST['user_id'] ?? 0);
    $status = (string)($_POST['status'] ?? '');
    if ($id > 0 && in_array($status, ['active','suspended'], true)) {
        $pdo->prepare('UPDATE users SET status=? WHERE id=? AND role="user"')->execute([$status,$id]);
        $notice = 'Kullanıcı durumu güncellendi.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'set_iap_mode') {
    $mode = (string)($_POST['mode'] ?? 'production');
    if (in_array($mode, ['production','development'], true)) {
        $configFile = __DIR__ . '/../app/config.php';
        $config = require $configFile;
        $config['iap']['mode'] = $mode;
        file_put_contents($configFile, "<?php\nreturn " . var_export($config, true) . ";\n", LOCK_EX);
        $notice = 'IAP modu güncellendi.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'sync_tmdb_trending') {
    $key = (string)cfg('tmdb.api_key','');
    if ($key === '') {
        $error = 'TMDB API key yapılandırılmamış.';
    } elseif (!function_exists('curl_init')) {
        $error = 'Sunucuda cURL etkin değil.';
    } else {
        $ch = curl_init('https://api.themoviedb.org/3/trending/all/week?api_key=' . rawurlencode($key) . '&language=tr-TR');
        curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>25,CURLOPT_CONNECTTIMEOUT=>8]);
        $raw = curl_exec($ch);
        $status = (int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);
        curl_close($ch);
        if ($raw === false || $status < 200 || $status >= 300) {
            $error = 'TMDB verisi alınamadı.';
        } else {
            $data = json_decode((string)$raw,true);
            $count = 0;
            $stmt = $pdo->prepare(
                'INSERT INTO movies (tmdb_id,type,title,original_title,overview,poster_url,backdrop_url,release_year,genres_json,rating,popularity,created_at,updated_at)
                 VALUES (?,?,?,?,?,?,?,?,?,?,?,UTC_TIMESTAMP(),UTC_TIMESTAMP())
                 ON DUPLICATE KEY UPDATE title=VALUES(title),original_title=VALUES(original_title),overview=VALUES(overview),
                 poster_url=VALUES(poster_url),backdrop_url=VALUES(backdrop_url),release_year=VALUES(release_year),rating=VALUES(rating),popularity=VALUES(popularity),updated_at=UTC_TIMESTAMP()'
            );
            foreach (($data['results'] ?? []) as $item) {
                $type = ($item['media_type'] ?? '') === 'tv' ? 'series' : 'movie';
                if (($item['media_type'] ?? '') === 'person') continue;
                $title = (string)($item['title'] ?? $item['name'] ?? '');
                if ($title === '') continue;
                $date = (string)($item['release_date'] ?? $item['first_air_date'] ?? '');
                $year = preg_match('/^\d{4}/',$date,$m) ? (int)$m[0] : null;
                $poster = !empty($item['poster_path']) ? 'https://image.tmdb.org/t/p/w780'.$item['poster_path'] : null;
                $backdrop = !empty($item['backdrop_path']) ? 'https://image.tmdb.org/t/p/w1280'.$item['backdrop_path'] : null;
                $stmt->execute([
                    (int)$item['id'],$type,$title,
                    (string)($item['original_title'] ?? $item['original_name'] ?? ''),
                    (string)($item['overview'] ?? ''),$poster,$backdrop,$year,
                    json_encode([],JSON_UNESCAPED_UNICODE),
                    (float)($item['vote_average'] ?? 0),(float)($item['popularity'] ?? 0)
                ]);
                $count++;
            }
            $notice = "{$count} trend içerik TMDB'den senkronlandı.";
        }
    }
}

$counts = [
    'users' => (int)$pdo->query('SELECT COUNT(*) FROM users WHERE role="user"')->fetchColumn(),
    'movies' => (int)$pdo->query('SELECT COUNT(*) FROM movies')->fetchColumn(),
    'matches' => (int)$pdo->query('SELECT COUNT(*) FROM matches WHERE status="active"')->fetchColumn(),
    'messages' => (int)$pdo->query('SELECT COUNT(*) FROM messages')->fetchColumn(),
    'premium' => (int)$pdo->query('SELECT COUNT(*) FROM users WHERE premium_until>UTC_TIMESTAMP()')->fetchColumn(),
    'reports' => (int)$pdo->query('SELECT COUNT(*) FROM reports WHERE status<>"closed"')->fetchColumn(),
];

$users = $pdo->query('SELECT id,display_name,username,email,city,status,premium_until,created_at FROM users WHERE role="user" ORDER BY id DESC LIMIT 50')->fetchAll();
$subs = $pdo->query('SELECT s.*,u.email FROM subscriptions s INNER JOIN users u ON u.id=s.user_id ORDER BY s.id DESC LIMIT 30')->fetchAll();
$reports = $pdo->query('SELECT r.*,u.email reporter_email FROM reports r INNER JOIN users u ON u.id=r.reporter_id ORDER BY r.id DESC LIMIT 30')->fetchAll();
$iapMode = (string)cfg('iap.mode','production');
?>
<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SineMatch Yönetim</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#07080c;color:#fff;font:14px system-ui,-apple-system,Segoe UI,sans-serif}.wrap{max-width:1240px;margin:auto;padding:22px}.top{display:flex;align-items:center;gap:12px}.top h1{flex:1}.pink{color:#ff315f}.muted{color:#969bad}.btn,button{border:0;background:#ff315f;color:#fff;padding:10px 13px;border-radius:11px;text-decoration:none;font-weight:700;cursor:pointer}.btn.dark,button.dark{background:#1a1d26;border:1px solid #2c303c}.cards{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}.card,.panel{background:#11131a;border:1px solid #292c38;border-radius:20px;padding:18px}.num{font-size:28px;font-weight:900}.panel{margin-top:16px;overflow:auto}.panel h2{margin:0 0 14px}table{width:100%;border-collapse:collapse;min-width:760px}th,td{text-align:left;padding:11px;border-bottom:1px solid #262a35}th{color:#9297a8}select{background:#181b24;color:#fff;border:1px solid #303442;padding:8px;border-radius:9px}.msg{padding:12px 14px;border-radius:12px;margin:12px 0}.ok{background:#153d31}.err{background:#4a1822}.toolbar{display:flex;gap:10px;flex-wrap:wrap;align-items:center}.badge{display:inline-block;padding:4px 8px;border-radius:99px;background:#20232d}.premium{color:#ffc765}@media(max-width:950px){.cards{grid-template-columns:repeat(3,1fr)}}@media(max-width:600px){.cards{grid-template-columns:repeat(2,1fr)}.wrap{padding:12px}}
</style></head><body><div class="wrap">
<div class="top"><h1>Sine<span class="pink">Match</span> Yönetim</h1><span class="muted"><?=htmlspecialchars($admin['display_name'])?></span><a class="btn dark" href="logout.php">Çıkış</a></div>
<?php if($notice):?><div class="msg ok"><?=htmlspecialchars($notice)?></div><?php endif;?>
<?php if($error):?><div class="msg err"><?=htmlspecialchars($error)?></div><?php endif;?>
<div class="cards">
<?php foreach($counts as $k=>$v):?><div class="card"><div class="muted"><?=htmlspecialchars(ucfirst($k))?></div><div class="num"><?=$v?></div></div><?php endforeach;?>
</div>

<div class="panel"><h2>TMDB Tüm Film Kataloğu</h2>
<p class="muted">TMDB'nin resmi günlük film ID export dosyasını kullanır. İşlem parçalara bölünür, tarayıcı kapanırsa kaldığı yerden devam eder. Yetişkin veri seti dahil edilmez.</p>
<div class="toolbar">
<button type="button" id="tmdbStart">Tüm Filmleri Başlat / Devam Et</button>
<button type="button" class="dark" id="tmdbStop">Durdur</button>
<button type="button" class="dark" id="tmdbRefresh">Durumu Yenile</button>
</div>
<div id="tmdbStatus" class="msg" style="background:#181b24;margin-top:14px">Durum yükleniyor…</div>
<div style="height:10px;background:#20232d;border-radius:99px;overflow:hidden"><div id="tmdbBar" style="height:100%;width:0;background:#ff315f;transition:width .25s"></div></div>
<div id="tmdbStats" class="muted" style="margin-top:10px"></div>
</div>

<div class="panel"><h2>Sistem</h2><div class="toolbar">
<form method="post"><input type="hidden" name="action" value="sync_tmdb_trending"><button class="dark" type="submit">TMDB Trend Hızlı Senkron</button></form>
<form method="post" class="toolbar"><input type="hidden" name="action" value="set_iap_mode"><span class="muted">IAP:</span><select name="mode"><option value="production" <?=$iapMode==='production'?'selected':''?>>Production</option><option value="development" <?=$iapMode==='development'?'selected':''?>>Development/Demo</option></select><button class="dark">Kaydet</button></form>
<span class="muted">Production modunda receipt sunucu doğrulaması tamamlanmadan abonelik otomatik aktif edilmez.</span>
</div></div>

<div class="panel"><h2>Son Kullanıcılar</h2><table><thead><tr><th>ID</th><th>Kullanıcı</th><th>E-posta</th><th>Şehir</th><th>Premium</th><th>Durum</th><th>Kayıt</th><th>İşlem</th></tr></thead><tbody>
<?php foreach($users as $u):?><tr>
<td><?=$u['id']?></td><td><strong><?=htmlspecialchars($u['display_name'])?></strong><br><span class="muted">@<?=htmlspecialchars($u['username'])?></span></td>
<td><?=htmlspecialchars($u['email'])?></td><td><?=htmlspecialchars((string)$u['city'])?></td>
<td class="<?=($u['premium_until'] && strtotime($u['premium_until'])>time())?'premium':''?>"><?=htmlspecialchars((string)($u['premium_until'] ?: '-'))?></td>
<td><span class="badge"><?=htmlspecialchars($u['status'])?></span></td><td><?=htmlspecialchars($u['created_at'])?></td>
<td><form method="post" class="toolbar"><input type="hidden" name="action" value="set_user_status"><input type="hidden" name="user_id" value="<?=$u['id']?>"><select name="status"><option value="active">active</option><option value="suspended">suspended</option></select><button class="dark">Uygula</button></form></td>
</tr><?php endforeach;?></tbody></table></div>

<div class="panel"><h2>Premium Satın Almalar</h2><table><thead><tr><th>ID</th><th>E-posta</th><th>Ürün</th><th>Platform</th><th>Durum</th><th>Bitiş</th><th>Tarih</th></tr></thead><tbody>
<?php foreach($subs as $s):?><tr><td><?=$s['id']?></td><td><?=htmlspecialchars($s['email'])?></td><td><?=htmlspecialchars($s['product_id'])?></td><td><?=htmlspecialchars($s['platform'])?></td><td><?=htmlspecialchars($s['status'])?></td><td><?=htmlspecialchars((string)$s['expires_at'])?></td><td><?=htmlspecialchars($s['created_at'])?></td></tr><?php endforeach;?>
</tbody></table></div>

<div class="panel"><h2>Şikayetler</h2><table><thead><tr><th>ID</th><th>Bildiren</th><th>Hedef</th><th>Neden</th><th>Durum</th><th>Tarih</th></tr></thead><tbody>
<?php foreach($reports as $r):?><tr><td><?=$r['id']?></td><td><?=htmlspecialchars($r['reporter_email'])?></td><td><?=htmlspecialchars((string)$r['target_user_id'])?></td><td><?=htmlspecialchars($r['reason'])?></td><td><?=htmlspecialchars($r['status'])?></td><td><?=htmlspecialchars($r['created_at'])?></td></tr><?php endforeach;?>
</tbody></table></div>
</div>
<script>
(() => {
  let running = false;
  const status = document.getElementById('tmdbStatus');
  const stats = document.getElementById('tmdbStats');
  const bar = document.getElementById('tmdbBar');
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  async function call(action){
    const fd = new FormData(); fd.append('action', action);
    const r = await fetch('tmdb_sync.php', {method:'POST', body:fd, credentials:'same-origin'});
    const j = await r.json().catch(()=>({ok:false,message:'Geçersiz sunucu yanıtı'}));
    if(!r.ok || !j.ok) throw new Error(j.message || ('HTTP '+r.status));
    render(j.progress || {}); return j;
  }
  function render(p){
    const total=Number(p.total||0), synced=Number(p.synced||0), failed=Number(p.failed||0), pending=Number(p.pending||0);
    const pct=total>0?Math.min(100,Math.round(((synced+failed)/total)*100)):0;
    bar.style.width=pct+'%';
    stats.textContent=`Export: ${p.export_date||'-'} • Kuyruk: ${total.toLocaleString('tr-TR')} • Tamamlanan: ${synced.toLocaleString('tr-TR')} • Bekleyen: ${pending.toLocaleString('tr-TR')} • Hatalı: ${failed.toLocaleString('tr-TR')} • DB film: ${Number(p.movies_in_db||0).toLocaleString('tr-TR')} • %${pct}`;
    if(!p.export_ready) status.textContent='TMDB günlük film listesi henüz hazırlanmadı.';
    else if(!p.seed_done) status.textContent='TMDB film ID listesi veritabanına aktarılıyor…';
    else if(pending>0) status.textContent='Film detayları, Türkçe başlıklar, açıklamalar ve görseller senkronlanıyor…';
    else if(total>0) status.textContent='TMDB film kataloğu senkronu tamamlandı.';
  }
  async function progress(){ try{ await call('progress'); }catch(e){ status.textContent='Hata: '+e.message; } }
  async function run(){
    if(running) return; running=true;
    try{
      status.textContent='TMDB günlük export dosyası hazırlanıyor…';
      let j=await call('prepare');
      while(running && !(j.progress&&j.progress.seed_done)){
        j=await call('seed'); await sleep(120);
      }
      while(running && j.progress && Number(j.progress.pending||0)>0){
        j=await call('enrich');
        if(j.result && j.result.rate_limited){ status.textContent='TMDB hız limiti devreye girdi; kısa bekleme sonrası devam ediliyor…'; await sleep(5000); }
        else await sleep(500);
      }
      if(running){ status.textContent='TMDB tüm film kataloğu senkronu tamamlandı.'; await progress(); }
    }catch(e){ status.textContent='Hata: '+e.message; }
    running=false;
  }
  document.getElementById('tmdbStart').onclick=run;
  document.getElementById('tmdbStop').onclick=()=>{running=false;status.textContent='Senkron durduruldu. Tekrar Başlat / Devam Et ile kaldığı yerden sürer.'};
  document.getElementById('tmdbRefresh').onclick=progress;
  progress();
})();
</script>
</body></html>
