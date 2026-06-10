-- =====================================================================
-- PROJE 3: Veritabanı Güvenliği ve Erişim Kontrolü
-- Dosya 01: Veritabanı oluşturma
-- DBMS: PostgreSQL 18  |  Senaryo: Banka (hassas veri güvenliği)
-- 'postgres' veritabanına bağlıyken çalıştırın.
-- =====================================================================

DROP DATABASE IF EXISTS guvenlik_db;

CREATE DATABASE guvenlik_db
    WITH ENCODING 'UTF8'
         TEMPLATE template0;

COMMENT ON DATABASE guvenlik_db IS 'BLM4522 Proje 3 - Veritabani guvenligi, sifreleme, audit demo';
