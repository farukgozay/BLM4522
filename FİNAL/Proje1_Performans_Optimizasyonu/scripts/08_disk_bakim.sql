-- =====================================================================
-- PROJE 1 - Dosya 08: Disk Alanı ve Veri Yoğunluğu Yönetimi
-- PDF gereksinimi: "disk alanı yönetimi ve veri yoğunluğunun yönetimi"
--
-- PostgreSQL'de UPDATE/DELETE sonrası "ölü satırlar" (dead tuples) oluşur
-- ve tablo şişer (bloat). VACUUM bu alanı geri kazanır.
-- =====================================================================

\echo '== 1) Veritabani toplam boyutu =='
SELECT pg_size_pretty(pg_database_size('banka_db')) AS veritabani_boyutu;

\echo ''
\echo '== 2) Tablo basina disk kullanimi (en buyukten) =='
SELECT relname AS tablo,
       pg_size_pretty(pg_total_relation_size(relid)) AS toplam,
       pg_size_pretty(pg_relation_size(relid))       AS veri,
       pg_size_pretty(pg_indexes_size(relid))        AS indeksler
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- ---------------------------------------------------------------------
-- 3) BLOAT (şişme) oluşturup geri kazanma demosu
-- ---------------------------------------------------------------------
\echo ''
\echo '== 3a) Once: islemler olu satir sayisi =='
SELECT n_live_tup AS canli, n_dead_tup AS olu FROM pg_stat_user_tables WHERE relname='islemler';

-- 200.000 satırı güncelle -> 200.000 ölü satır oluşur (bloat)
UPDATE islemler SET aciklama = aciklama || ' [guncellendi]'
WHERE islem_id <= 200000;

\echo '== 3b) UPDATE sonrasi: olu satirlar artti =='
SELECT n_live_tup AS canli, n_dead_tup AS olu FROM pg_stat_user_tables WHERE relname='islemler';
SELECT pg_size_pretty(pg_total_relation_size('islemler')) AS update_sonrasi_boyut;

-- VACUUM: ölü satırların yerini yeniden kullanılabilir yapar
VACUUM (VERBOSE, ANALYZE) islemler;

\echo '== 3c) VACUUM sonrasi: olu satirlar temizlendi =='
SELECT n_live_tup AS canli, n_dead_tup AS olu FROM pg_stat_user_tables WHERE relname='islemler';

-- ---------------------------------------------------------------------
-- 4) DELETE + VACUUM FULL ile diske alan iadesi
-- ---------------------------------------------------------------------
\echo ''
\echo '== 4) Eski (2022) kayitlari silip diski geri kazanma =='
SELECT count(*) AS silinecek_2022_kayit FROM islemler WHERE islem_tarihi < '2023-01-01';

DELETE FROM islemler WHERE islem_tarihi < '2023-01-01';
\echo 'Boyut (DELETE sonrasi, henuz disk iade edilmedi):'
SELECT pg_size_pretty(pg_total_relation_size('islemler')) AS boyut;

-- VACUUM FULL tabloyu yeniden yazar ve diski isletim sistemine geri verir
-- (DIKKAT: tabloyu kilitler, uzun surebilir - demo amacli)
VACUUM FULL islemler;
\echo 'Boyut (VACUUM FULL sonrasi - disk geri kazanildi):'
SELECT pg_size_pretty(pg_total_relation_size('islemler')) AS boyut;

-- ---------------------------------------------------------------------
-- 5) Autovacuum ayarlarını kontrol
-- ---------------------------------------------------------------------
\echo ''
\echo '== 5) Autovacuum durumu ve son calisma zamanlari =='
SELECT relname AS tablo,
       last_vacuum, last_autovacuum,
       last_analyze, last_autoanalyze,
       vacuum_count, autovacuum_count
FROM pg_stat_user_tables
ORDER BY relname;

\echo '### Disk/veri yogunlugu bakimi tamamlandi ###'
