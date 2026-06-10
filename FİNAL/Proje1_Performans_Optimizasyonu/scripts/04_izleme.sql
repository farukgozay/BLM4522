-- =====================================================================
-- PROJE 1 - Dosya 04: Veritabanı İzleme
-- PDF gereksinimi: "SQL Profiler, Dynamic Management Views (DMV) gibi
-- araçlarla sorgu performansını izleme ve hataları tespit etme."
--
-- PostgreSQL karşılıkları:
--   SQL Server DMV / Profiler   ->  pg_stat_*, pg_statio_* görünümleri
--                                   ve pg_stat_statements eklentisi
-- Bu dosyadaki görünümler eklenti gerektirmez, her zaman çalışır.
-- =====================================================================

\echo '== 1) Aktif oturumlar ve o an çalışan sorgular (SQL Server: sys.dm_exec_requests) =='
SELECT pid,
       usename            AS kullanici,
       state              AS durum,
       wait_event_type    AS bekleme_tipi,
       now() - query_start AS calisma_suresi,
       left(query, 80)    AS sorgu
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY calisma_suresi DESC NULLS LAST;

\echo ''
\echo '== 2) Tablo boyutları ve canli/olu satir sayisi (veri yogunlugu) =='
SELECT relname                                   AS tablo,
       n_live_tup                                AS canli_satir,
       n_dead_tup                                AS olu_satir,
       pg_size_pretty(pg_total_relation_size(relid)) AS toplam_boyut,
       pg_size_pretty(pg_relation_size(relid))   AS sadece_veri,
       pg_size_pretty(pg_indexes_size(relid))    AS indeks_boyutu
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

\echo ''
\echo '== 3) Tablo erisim istatistikleri: seq scan vs index scan =='
-- seq_scan yüksek + idx_scan düşük olan tablolar indeks adayıdır.
SELECT relname            AS tablo,
       seq_scan           AS tam_tarama_sayisi,
       seq_tup_read       AS taranan_satir,
       idx_scan           AS indeks_tarama_sayisi,
       n_tup_ins          AS eklenen,
       n_tup_upd          AS guncellenen,
       n_tup_del          AS silinen
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC;

\echo ''
\echo '== 4) Cache (buffer) isabet orani - hedef > %99 =='
SELECT relname AS tablo,
       heap_blks_read                                   AS diskten_okuma,
       heap_blks_hit                                    AS cacheten_okuma,
       round(100.0 * heap_blks_hit /
             NULLIF(heap_blks_hit + heap_blks_read, 0), 2) AS cache_isabet_yuzdesi
FROM pg_statio_user_tables
ORDER BY heap_blks_read DESC;

\echo ''
\echo '== 5) Indeks kullanim istatistikleri (hic kullanilmayan indeksleri tespit) =='
SELECT indexrelname AS indeks,
       relname      AS tablo,
       idx_scan     AS kullanim_sayisi,
       pg_size_pretty(pg_relation_size(indexrelid)) AS boyut
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;

-- =====================================================================
-- pg_stat_statements (SQL Server "en pahali sorgular" raporunun karsiligi)
-- ---------------------------------------------------------------------
-- Bu eklenti shared_preload_libraries icinde olmalidir. Etkinlestirmek
-- icin scripts/00_enable_pg_stat_statements.sql dosyasini calistirin ve
-- PostgreSQL servisini yeniden baslatin. Etkinse asagidaki sorgu en cok
-- toplam sure tuketen sorgulari listeler:
-- =====================================================================
\echo ''
\echo '== 6) pg_stat_statements - en pahali sorgular (eklenti etkinse) =='
SELECT
    round(total_exec_time::numeric, 1) AS toplam_ms,
    calls                              AS cagri_sayisi,
    round(mean_exec_time::numeric, 3)  AS ortalama_ms,
    rows                               AS donen_satir,
    left(query, 70)                    AS sorgu
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
