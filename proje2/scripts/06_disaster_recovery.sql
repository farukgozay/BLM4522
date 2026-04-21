-- =====================================================
-- PROJE 2: Felaketten Kurtarma Senaryoları
-- Çeşitli felaket durumlarında veritabanı kurtarma
-- =====================================================

-- ========================
-- SENARYO 1: Kazara Tablo Silme
-- ========================

-- Adım 1: Mevcut durumu kontrol et
SELECT 'Silme oncesi musteri sayisi:' AS bilgi, COUNT(*)::TEXT AS deger FROM musteriler
UNION ALL
SELECT 'Silme oncesi siparis sayisi:', COUNT(*)::TEXT FROM siparisler;

-- Adım 2: Kazara tabloyu sil (felaket simülasyonu)
-- DİKKAT: Bu komutu sadece test amaçlı çalıştırın!
-- DROP TABLE IF EXISTS musteriler CASCADE;

-- Adım 3: pg_restore ile tabloyu geri yükle
-- Terminalden çalıştırın:
-- pg_restore -d eticaret_db -t musteriler --data-only "C:\pg_backups\full\full_backup_XXXXXXXX.dump"


-- ========================
-- SENARYO 2: Kazara Veri Silme (DELETE)
-- ========================

-- Adım 1: Savepoint oluştur (transaction içinde çalışmak)
BEGIN;
SAVEPOINT once_savepoint;

-- Mevcut kayıt sayısı
SELECT COUNT(*) AS silme_oncesi FROM musteriler;

-- Adım 2: Kazara silme simülasyonu
DELETE FROM musteriler WHERE sehir = 'İstanbul';
SELECT COUNT(*) AS silme_sonrasi FROM musteriler;

-- Adım 3: Rollback ile geri al
ROLLBACK TO SAVEPOINT once_savepoint;
SELECT COUNT(*) AS rollback_sonrasi FROM musteriler;

COMMIT;


-- ========================
-- SENARYO 3: Point-in-Time Recovery (PITR)
-- ========================

-- Adım 1: Kurtarma noktası zamanını belirle
SELECT CURRENT_TIMESTAMP AS kurtarma_noktasi;

-- Adım 2: PITR için recovery.conf / postgresql.conf ayarları
-- postgresql.conf'a eklenecek (sunucu kapalıyken):
--
--   restore_command = 'copy "C:\\pg_backups\\wal_archive\\%f" "%p"'
--   recovery_target_time = '2026-04-20 15:30:00'
--   recovery_target_action = 'promote'
--
-- Ardından data dizinine "recovery.signal" dosyası oluşturun
-- ve PostgreSQL'i yeniden başlatın.


-- ========================
-- SENARYO 4: Tüm Veritabanını Geri Yükleme
-- ========================

-- Terminalden çalıştırılacak komutlar:

-- 1. Mevcut bağlantıları kes
-- SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
-- WHERE datname = 'eticaret_db' AND pid <> pg_backend_pid();

-- 2. Veritabanını sil
-- DROP DATABASE IF EXISTS eticaret_db;

-- 3. Boş veritabanı oluştur
-- CREATE DATABASE eticaret_db;

-- 4. Yedekten geri yükle
-- pg_restore -d eticaret_db -v "C:\pg_backups\full\full_backup_XXXXXXXX.dump"


-- ========================
-- SENARYO 5: Belirli Tabloyu Geri Yükleme
-- ========================

-- Sadece siparis tablosunu yedekten geri yükle:
-- pg_restore -d eticaret_db -t siparisler -t siparis_detaylari --clean "C:\pg_backups\full\full_backup_XXXXXXXX.dump"


-- ========================
-- Kurtarma İşlemi Sonrası Doğrulama
-- ========================

-- Tüm tabloların kayıt sayılarını kontrol et
SELECT schemaname, relname AS tablo, n_live_tup AS kayit_sayisi
FROM pg_stat_user_tables
ORDER BY relname;

-- Veri bütünlüğü kontrolü (foreign key ilişkileri)
SELECT 'Yetim siparisler (musteri_id gecersiz)' AS kontrol,
       COUNT(*) AS sorunlu_kayit
FROM siparisler s
LEFT JOIN musteriler m ON s.musteri_id = m.musteri_id
WHERE m.musteri_id IS NULL

UNION ALL

SELECT 'Yetim siparis detaylari (siparis_id gecersiz)',
       COUNT(*)
FROM siparis_detaylari sd
LEFT JOIN siparisler s ON sd.siparis_id = s.siparis_id
WHERE s.siparis_id IS NULL

UNION ALL

SELECT 'Yetim odemeler (siparis_id gecersiz)',
       COUNT(*)
FROM odemeler o
LEFT JOIN siparisler s ON o.siparis_id = s.siparis_id
WHERE s.siparis_id IS NULL;

-- Son yedekleme loglarını göster
SELECT log_id, yedek_tipi, durum, baslangic_zamani, bitis_zamani, boyut_mb
FROM yedekleme_log
ORDER BY log_id DESC
LIMIT 10;
