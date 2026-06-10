-- =====================================================================
-- PROJE 1 - Dosya 07: Veri Yöneticisi Rolleri
-- PDF gereksinimi: "Veri Yöneticisi Rolleri: Farklı roller için erişim yönetimi."
--
-- 3 farklı rol oluşturup yetkilerini ayırıyoruz:
--   1) rol_rapor   -> sadece OKUMA (raporlama/analist)
--   2) rol_operator-> okuma + işlem ekleme (gişe personeli)
--   3) rol_dba     -> tam yetki (veritabanı yöneticisi)
-- =====================================================================

-- Temizlik (tekrar çalıştırılabilirlik)
DROP ROLE IF EXISTS analist_ayse;
DROP ROLE IF EXISTS gise_mehmet;
DROP ROLE IF EXISTS dba_admin;
DROP ROLE IF EXISTS rol_rapor;
DROP ROLE IF EXISTS rol_operator;
DROP ROLE IF EXISTS rol_dba;

-- ---------------------------------------------------------------------
-- 1) GRUP ROLLERİ (yetki şablonları) - NOLOGIN
-- ---------------------------------------------------------------------
CREATE ROLE rol_rapor    NOLOGIN;
CREATE ROLE rol_operator NOLOGIN;
CREATE ROLE rol_dba      NOLOGIN;

-- rol_rapor: tüm tablolarda yalnızca SELECT
GRANT CONNECT ON DATABASE banka_db TO rol_rapor;
GRANT USAGE ON SCHEMA public TO rol_rapor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_rapor;
-- Gelecekte oluşturulacak tablolar için de otomatik SELECT
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_rapor;

-- rol_operator: rapor + işlem ekleme/güncelleme (ama silme YOK)
GRANT rol_rapor TO rol_operator;
GRANT INSERT, UPDATE ON islemler, hesaplar TO rol_operator;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_operator;

-- rol_dba: şema üzerinde tam yetki
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_dba;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_dba;
GRANT CREATE ON SCHEMA public TO rol_dba;

-- ---------------------------------------------------------------------
-- 2) GERÇEK KULLANICILAR (LOGIN) ve rol ataması
-- ---------------------------------------------------------------------
CREATE ROLE analist_ayse LOGIN PASSWORD 'Analist*2025';
CREATE ROLE gise_mehmet  LOGIN PASSWORD 'Gise*2025';
CREATE ROLE dba_admin    LOGIN PASSWORD 'Dba*2025';

GRANT rol_rapor    TO analist_ayse;
GRANT rol_operator TO gise_mehmet;
GRANT rol_dba      TO dba_admin;

-- ---------------------------------------------------------------------
-- 3) DOĞRULAMA - yetki matrisini göster
-- ---------------------------------------------------------------------
\echo '### Rol uyelikleri ###'
SELECT r.rolname AS kullanici, m.rolname AS sahip_oldugu_rol
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname IN ('analist_ayse','gise_mehmet','dba_admin')
ORDER BY 1;

\echo '### islemler tablosu uzerindeki yetkiler ###'
SELECT grantee AS kime, privilege_type AS yetki
FROM information_schema.role_table_grants
WHERE table_name = 'islemler' AND grantee LIKE 'rol_%'
ORDER BY grantee, privilege_type;

-- ---------------------------------------------------------------------
-- TEST komutları (video için - manuel çalıştır):
--   psql -U analist_ayse -d banka_db
--   SELECT count(*) FROM islemler;          --> ÇALIŞIR (okuma izni var)
--   DELETE FROM islemler WHERE islem_id=1;  --> HATA: permission denied
-- ---------------------------------------------------------------------
\echo '### Roller olusturuldu. analist_ayse sadece okuyabilir, silemez. ###'
