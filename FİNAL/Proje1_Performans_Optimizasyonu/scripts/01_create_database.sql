-- =====================================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Dosya 01: Veritabanı oluşturma
-- DBMS: PostgreSQL 18
-- Senaryo: Banka / Finans sistemi
-- =====================================================================
-- NOT: Bu dosya 'postgres' veritabanına bağlıyken çalıştırılmalıdır.
--      CREATE DATABASE bir transaction bloğu içinde çalışmaz.
-- =====================================================================

-- Eğer önceden varsa düşür (tekrar çalıştırılabilir olması için)
DROP DATABASE IF EXISTS banka_db;

-- Performans projesi için ana veritabanı
CREATE DATABASE banka_db
    WITH ENCODING 'UTF8'
         TEMPLATE template0;

COMMENT ON DATABASE banka_db IS 'BLM4522 Proje 1 - Banka performans optimizasyonu demo veritabanı';
