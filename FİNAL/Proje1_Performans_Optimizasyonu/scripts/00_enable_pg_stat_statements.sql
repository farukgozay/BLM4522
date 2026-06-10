-- =====================================================================
-- PROJE 1 - Dosya 00 (OPSİYONEL): pg_stat_statements etkinleştirme
-- "En pahalı sorgular" raporu (SQL Server sys.dm_exec_query_stats karşılığı)
-- için bu eklenti gereklidir.
--
-- ADIMLAR:
--   1) Bu komutu 'postgres' süper kullanıcı ile çalıştırın:
--        ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
--   2) PostgreSQL servisini YENİDEN BAŞLATIN:
--        (Windows) net stop postgresql-x64-18 && net start postgresql-x64-18
--        veya Hizmetler (services.msc) panelinden.
--   3) banka_db'ye bağlanıp eklentiyi oluşturun:
--        CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- =====================================================================

ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
-- !!! Bu komuttan SONRA servisi yeniden başlatmadan etki etmez !!!

-- Servis yeniden başladıktan SONRA banka_db üzerinde:
--   CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
