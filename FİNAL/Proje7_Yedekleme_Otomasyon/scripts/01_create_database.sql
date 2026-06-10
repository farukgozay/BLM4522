-- =====================================================================
-- PROJE 7: Veritabanı Yedekleme ve Otomasyon Çalışması
-- Dosya 01: Veritabanı + yedekleme log tablosu
-- DBMS: PostgreSQL 18  |  Senaryo: Banka
-- 'postgres' veritabanına bağlıyken çalıştırın.
-- =====================================================================

DROP DATABASE IF EXISTS yedekleme_db;
CREATE DATABASE yedekleme_db WITH ENCODING 'UTF8' TEMPLATE template0;

\c yedekleme_db

-- İş verisi (yedeklenecek tablolar) -----------------------------------
CREATE TABLE musteriler (
    musteri_id  SERIAL PRIMARY KEY,
    ad          VARCHAR(50),
    soyad       VARCHAR(50),
    sehir       VARCHAR(50),
    kayit       TIMESTAMP DEFAULT now()
);

CREATE TABLE islemler (
    islem_id     BIGSERIAL PRIMARY KEY,
    musteri_id   INT REFERENCES musteriler(musteri_id),
    tutar        NUMERIC(12,2),
    islem_tarihi TIMESTAMP DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Yedekleme denetim tablosu: her yedek işlemi buraya kaydedilir.
-- (PowerShell scripti bu tabloya yazar; raporlama buradan okur.)
-- ---------------------------------------------------------------------
CREATE TABLE yedekleme_log (
    log_id        SERIAL PRIMARY KEY,
    yedek_tipi    VARCHAR(20) NOT NULL,         -- 'tam' (full)
    dosya_adi     TEXT,
    baslangic     TIMESTAMP NOT NULL DEFAULT now(),
    bitis         TIMESTAMP,
    boyut_mb      NUMERIC(10,2),
    durum         VARCHAR(15) NOT NULL DEFAULT 'basladi',  -- basladi/basarili/basarisiz
    hata_mesaji   TEXT
);

COMMENT ON TABLE yedekleme_log IS 'Otomatik yedekleme islemlerinin denetim kaydi';

\echo '### yedekleme_db ve yedekleme_log tablosu olusturuldu ###'
