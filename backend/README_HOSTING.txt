SineMatch Backend v1.0.2 - Plesk / PHP 7.4+ / MySQL

Kurulum:
1) Bu klasörün içeriğini Plesk domain document root'una (genellikle httpdocs) yükleyin.
2) https://alanadiniz/install.php adresini açın.
3) Kurulumdan sonra https://alanadiniz/admin/ ile giriş yapın.
4) Admin > TMDB Tüm Film Kataloğu > "Tüm Filmleri Başlat / Devam Et" butonuna basın.

TMDB TAM KATALOG:
- /discover/movie tek başına tüm TMDB'yi vermez; TMDB API sayfa numarası en fazla 500'dür.
- Bu sürüm TMDB'nin resmi Daily ID Export dosyasını kullanır.
- Film ID'leri parça parça kuyruğa alınır ve detaylar 20'şerli batch'lerle çekilir.
- İşlem tarayıcı kapansa bile kaldığı yerden devam eder.
- Günlük export bulunamazsa sistem son birkaç günü otomatik dener.
- Yetişkin film export'u dahil değildir.
- Çok büyük katalog nedeniyle ilk tam detay senkronu uzun sürebilir; bu normaldir.

Gereksinimler:
- PHP 7.4+
- PDO MySQL
- cURL
- mbstring
- zlib/gzip
- MySQL 5.7+ / MariaDB JSON desteği

Güvenlik:
Kurulum tamamlandığında install.php ve diagnostics.php dosyalarını silin.
