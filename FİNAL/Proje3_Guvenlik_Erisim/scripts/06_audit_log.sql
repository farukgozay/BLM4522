-- =====================================================================
-- PROJE 3 - Dosya 06: Audit (Denetim) Logları
-- PDF gereksinimi: "Kullanıcı aktivitelerini izlemek için SQL Server Audit
-- özelliklerinin kullanımı."
--
-- PostgreSQL karşılığı: TRIGGER tabanlı audit tablosu (her yerde çalışır) +
-- statement düzeyinde denetim için pgAudit eklentisi.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Audit log tablosu
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    log_id      BIGSERIAL PRIMARY KEY,
    tablo_adi   TEXT NOT NULL,
    islem       TEXT NOT NULL,                -- INSERT / UPDATE / DELETE
    yapan_kullanici TEXT NOT NULL DEFAULT current_user,
    islem_zamani    TIMESTAMP NOT NULL DEFAULT current_timestamp,
    eski_veri   JSONB,
    yeni_veri   JSONB
);

-- ---------------------------------------------------------------------
-- 2) Tüm DML işlemlerini yakalayan tek trigger fonksiyonu
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit() RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log(tablo_adi, islem, eski_veri)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log(tablo_adi, islem, eski_veri, yeni_veri)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log(tablo_adi, islem, yeni_veri)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 3) Hassas tablolara trigger bağla
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_musteriler ON musteriler;
CREATE TRIGGER trg_audit_musteriler
    AFTER INSERT OR UPDATE OR DELETE ON musteriler
    FOR EACH ROW EXECUTE FUNCTION fn_audit();

DROP TRIGGER IF EXISTS trg_audit_hesaplar ON hesaplar;
CREATE TRIGGER trg_audit_hesaplar
    AFTER INSERT OR UPDATE OR DELETE ON hesaplar
    FOR EACH ROW EXECUTE FUNCTION fn_audit();

-- ---------------------------------------------------------------------
-- 4) DEMO: birkaç işlem yap, audit otomatik kaydetsin
-- ---------------------------------------------------------------------
\echo '### Ornek islemler yapiliyor (insert/update/delete) ###'
INSERT INTO musteriler (ad, soyad, tc_kimlik, telefon, sehir)
VALUES ('Test', 'Kullanici', '11111111111', '05551112233', 'Ankara');

UPDATE hesaplar SET bakiye = bakiye + 1000 WHERE hesap_id = 1;

DELETE FROM musteriler WHERE tc_kimlik = '11111111111';

-- ---------------------------------------------------------------------
-- 5) Audit log'u görüntüle - kim, neyi, ne zaman değiştirdi
-- ---------------------------------------------------------------------
\echo '### AUDIT LOG - tum kullanici aktiviteleri ###'
SELECT log_id, tablo_adi, islem, yapan_kullanici,
       to_char(islem_zamani,'HH24:MI:SS') AS saat
FROM audit_log
ORDER BY log_id;

\echo '### Bir UPDATE kaydinin eski/yeni degeri (bakiye degisimi): ###'
SELECT eski_veri->>'bakiye' AS eski_bakiye, yeni_veri->>'bakiye' AS yeni_bakiye
FROM audit_log WHERE islem='UPDATE' AND tablo_adi='hesaplar' LIMIT 1;

-- ---------------------------------------------------------------------
-- pgAudit notu: Sistem genelinde (her SELECT/DDL dahil) denetim için:
--   ALTER SYSTEM SET shared_preload_libraries = 'pgaudit';  (servis restart)
--   CREATE EXTENSION pgaudit;  SET pgaudit.log = 'write,ddl';
-- Bu, SQL Server Audit'in birebir karşılığıdır (log dosyasına yazar).
-- ---------------------------------------------------------------------
\echo '### Audit demosu tamamlandi ###'
