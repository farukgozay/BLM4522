-- =====================================================
-- PROJE 2: Yedekleme Doğrulama ve Test Senaryoları
-- Yedeklerin güvenilirliğini test etme
-- =====================================================

-- ========================
-- TEST 1: Yedek Dosya Bütünlüğü Kontrolü
-- ========================

-- pg_restore ile yedek dosyasını doğrula (geri yükleme yapmadan)
-- Terminalden çalıştırın:
-- pg_restore --list "C:\pg_backups\full\full_backup_XXXXXXXX.dump"
-- Hatasız çalışırsa dosya sağlamdır.


-- ========================
-- TEST 2: Test Veritabanına Geri Yükleme
-- ========================

-- 1. Test DB oluştur
-- CREATE DATABASE eticaret_db_test;

-- 2. Yedekten test DB'ye geri yükle
-- pg_restore -d eticaret_db_test "C:\pg_backups\full\full_backup_XXXXXXXX.dump"

-- 3. Kayıt sayılarını karşılaştır
-- Orijinal DB:
SELECT 'ORIJINAL' AS kaynak, 'musteriler' AS tablo, COUNT(*) AS kayit FROM musteriler
UNION ALL SELECT 'ORIJINAL', 'urunler', COUNT(*) FROM urunler
UNION ALL SELECT 'ORIJINAL', 'siparisler', COUNT(*) FROM siparisler
UNION ALL SELECT 'ORIJINAL', 'siparis_detaylari', COUNT(*) FROM siparis_detaylari
UNION ALL SELECT 'ORIJINAL', 'odemeler', COUNT(*) FROM odemeler
UNION ALL SELECT 'ORIJINAL', 'kategoriler', COUNT(*) FROM kategoriler;

-- Test DB için aynı sorguyu eticaret_db_test üzerinde çalıştırın
-- ve sonuçları karşılaştırın.


-- ========================
-- TEST 3: Checksum Karşılaştırma
-- ========================

-- Orijinal tablodaki verilerin hash kontrolü
SELECT md5(string_agg(musteri_id::TEXT || ad || soyad || email, ',' ORDER BY musteri_id)) 
    AS musteri_hash FROM musteriler;

SELECT md5(string_agg(urun_id::TEXT || urun_adi || fiyat::TEXT, ',' ORDER BY urun_id)) 
    AS urun_hash FROM urunler;

SELECT md5(string_agg(siparis_id::TEXT || musteri_id::TEXT || toplam_tutar::TEXT, ',' ORDER BY siparis_id)) 
    AS siparis_hash FROM siparisler;

-- Bu hash değerlerini test DB'deki sonuçlarla karşılaştırın.
-- Eşleşiyorsa yedek %100 doğrudur.


-- ========================
-- TEST 4: Yapısal Bütünlük Kontrolü
-- ========================

-- Tüm tabloların mevcut olduğunu kontrol et
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- İndekslerin mevcut olduğunu kontrol et
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;

-- Foreign key kısıtlamalarını kontrol et
SELECT
    tc.constraint_name,
    tc.table_name AS kaynak_tablo,
    kcu.column_name AS kaynak_sutun,
    ccu.table_name AS hedef_tablo,
    ccu.column_name AS hedef_sutun
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name;


-- ========================
-- TEST 5: Yedekleme Raporu
-- ========================

-- Yedekleme istatistikleri
SELECT
    yedek_tipi,
    COUNT(*) AS toplam_yedek,
    COUNT(*) FILTER (WHERE durum = 'basarili') AS basarili,
    COUNT(*) FILTER (WHERE durum = 'basarisiz') AS basarisiz,
    ROUND(AVG(boyut_mb), 2) AS ortalama_boyut_mb,
    MIN(baslangic_zamani) AS ilk_yedek,
    MAX(baslangic_zamani) AS son_yedek,
    ROUND(AVG(EXTRACT(EPOCH FROM (bitis_zamani - baslangic_zamani))), 1) AS ort_sure_sn
FROM yedekleme_log
GROUP BY yedek_tipi
ORDER BY yedek_tipi;

-- Veritabanı boyutu
SELECT pg_database.datname AS veritabani,
       pg_size_pretty(pg_database_size(pg_database.datname)) AS boyut
FROM pg_database
WHERE datname = 'eticaret_db';

-- Tablo boyutları
SELECT relname AS tablo,
       pg_size_pretty(pg_total_relation_size(relid)) AS toplam_boyut,
       pg_size_pretty(pg_relation_size(relid)) AS veri_boyutu,
       pg_size_pretty(pg_indexes_size(relid)) AS indeks_boyutu
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;


-- ========================
-- TEST 6: Test DB Temizliği
-- ========================

-- Test bittikten sonra test veritabanını silin:
-- DROP DATABASE IF EXISTS eticaret_db_test;
