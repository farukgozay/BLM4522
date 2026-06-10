-- =====================================================================
-- PROJE 3 - Dosya 04: Erişim Yönetimi
-- PDF gereksinimi: "Kullanıcıların verilere erişim yetkilerini yönetmek için
-- SQL Server Authentication ve Windows Authentication kullanma."
--
-- PostgreSQL karşılıkları (kimlik doğrulama pg_hba.conf'ta yapılır):
--   SQL Server Authentication  -> 'scram-sha-256' (parola tabanlı)
--   Windows Authentication     -> 'sspi' / 'peer' (işletim sistemi entegre)
-- =====================================================================

-- Temizlik
DROP ROLE IF EXISTS gise_personeli;
DROP ROLE IF EXISTS sube_muduru;
DROP ROLE IF EXISTS rol_gise;
DROP ROLE IF EXISTS rol_mudur;

-- ---------------------------------------------------------------------
-- 1) Kimlik doğrulama yöntemlerini görüntüle (pg_hba.conf kuralları)
--    Bu, "hangi kullanıcı nereden hangi yöntemle bağlanabilir" tablosudur.
-- ---------------------------------------------------------------------
\echo '### Aktif kimlik dogrulama kurallari (pg_hba.conf) ###'
SELECT type, database, user_name, address, auth_method
FROM pg_hba_file_rules
WHERE auth_method IS NOT NULL
ORDER BY rule_number;
-- Not: 'scram-sha-256' = parola dogrulama (SQL Server Auth karsiligi)
--      'sspi'          = Windows entegre dogrulama (Windows Auth karsiligi)

-- ---------------------------------------------------------------------
-- 2) ROL TABANLI ERİŞİM + SÜTUN BAZLI YETKİ
--    Gişe personeli müşteri adını görebilir ama TC KİMLİĞİ GÖREMEZ.
--    Şube müdürü tüm alanları görebilir.
-- ---------------------------------------------------------------------
CREATE ROLE rol_gise  NOLOGIN;
CREATE ROLE rol_mudur NOLOGIN;

GRANT CONNECT ON DATABASE guvenlik_db TO rol_gise, rol_mudur;
GRANT USAGE ON SCHEMA public TO rol_gise, rol_mudur;

-- Gişe: sadece belirli SÜTUNLARI okuyabilir (tc_kimlik HARİÇ)
GRANT SELECT (musteri_id, ad, soyad, telefon, sehir) ON musteriler TO rol_gise;
-- Gişe hesap bakiyesini göremez, sadece IBAN'ı görür
GRANT SELECT (hesap_id, musteri_id, iban) ON hesaplar TO rol_gise;

-- Müdür: tüm sütunları okuyabilir + güncelleyebilir
GRANT SELECT, UPDATE ON musteriler, hesaplar TO rol_mudur;

-- Gerçek kullanıcılar (LOGIN) - parola tabanlı (SQL Server Auth gibi)
CREATE ROLE gise_personeli LOGIN PASSWORD 'Gise*2025';
CREATE ROLE sube_muduru    LOGIN PASSWORD 'Mudur*2025';
GRANT rol_gise  TO gise_personeli;
GRANT rol_mudur TO sube_muduru;

-- ---------------------------------------------------------------------
-- 3) Yetki matrisini doğrula
-- ---------------------------------------------------------------------
\echo '### musteriler tablosunda SUTUN bazli yetkiler ###'
SELECT grantee AS kime, column_name AS sutun, privilege_type AS yetki
FROM information_schema.column_privileges
WHERE table_name = 'musteriler' AND grantee IN ('rol_gise','rol_mudur')
ORDER BY grantee, column_name;

-- ---------------------------------------------------------------------
-- TEST (video için manuel):
--   psql -U gise_personeli -d guvenlik_db
--   SELECT ad, soyad FROM musteriler LIMIT 3;     --> ÇALIŞIR
--   SELECT tc_kimlik FROM musteriler LIMIT 3;     --> HATA: permission denied for column tc_kimlik
-- ---------------------------------------------------------------------
\echo '### Roller hazir. gise_personeli tc_kimlik sutununu goremez. ###'
