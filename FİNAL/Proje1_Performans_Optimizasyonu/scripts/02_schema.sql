-- =====================================================================
-- PROJE 1 - Dosya 02: Tablo şeması (banka_db)
-- Bu dosya 'banka_db' veritabanına bağlıyken çalıştırılmalıdır.
-- =====================================================================
-- Tasarım notu: Büyük tablo olan 'islemler' üzerinde KASITLI olarak
-- bazı indeksler oluşturulmadı. İndeks yönetimi (05) ve sorgu
-- iyileştirme (06) adımlarında bu indeksleri ekleyip "önce/sonra"
-- performans farkını EXPLAIN ANALYZE ile göstereceğiz.
-- =====================================================================

-- Temizlik (tekrar çalıştırılabilirlik)
DROP TABLE IF EXISTS islemler      CASCADE;
DROP TABLE IF EXISTS kartlar       CASCADE;
DROP TABLE IF EXISTS hesaplar      CASCADE;
DROP TABLE IF EXISTS personel      CASCADE;
DROP TABLE IF EXISTS musteriler    CASCADE;
DROP TABLE IF EXISTS subeler       CASCADE;

-- ---------------------------------------------------------------------
-- Şubeler
-- ---------------------------------------------------------------------
CREATE TABLE subeler (
    sube_id      SERIAL PRIMARY KEY,
    sube_adi     VARCHAR(100) NOT NULL,
    sehir        VARCHAR(50)  NOT NULL,
    adres        TEXT,
    acilis_yili  INT
);

-- ---------------------------------------------------------------------
-- Müşteriler
-- ---------------------------------------------------------------------
CREATE TABLE musteriler (
    musteri_id    SERIAL PRIMARY KEY,
    ad            VARCHAR(50)  NOT NULL,
    soyad         VARCHAR(50)  NOT NULL,
    tc_kimlik     CHAR(11)     NOT NULL,
    email         VARCHAR(120),
    telefon       VARCHAR(20),
    dogum_tarihi  DATE,
    sehir         VARCHAR(50),
    kayit_tarihi  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    aktif         BOOLEAN DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- Personel (Veri Yöneticisi Rolleri demosu için şube personeli)
-- ---------------------------------------------------------------------
CREATE TABLE personel (
    personel_id   SERIAL PRIMARY KEY,
    sube_id       INT REFERENCES subeler(sube_id),
    ad            VARCHAR(50) NOT NULL,
    soyad         VARCHAR(50) NOT NULL,
    rol           VARCHAR(40) NOT NULL,           -- gise, mudur, uzman ...
    maas          NUMERIC(10,2),
    ise_giris     DATE
);

-- ---------------------------------------------------------------------
-- Hesaplar
-- ---------------------------------------------------------------------
CREATE TABLE hesaplar (
    hesap_id      SERIAL PRIMARY KEY,
    musteri_id    INT NOT NULL REFERENCES musteriler(musteri_id),
    sube_id       INT REFERENCES subeler(sube_id),
    iban          VARCHAR(34) NOT NULL,
    hesap_tipi    VARCHAR(20) NOT NULL CHECK (hesap_tipi IN ('vadesiz','vadeli','kredi','altin')),
    bakiye        NUMERIC(14,2) DEFAULT 0,
    para_birimi   CHAR(3) DEFAULT 'TRY',
    acilis_tarihi DATE DEFAULT CURRENT_DATE,
    durum         VARCHAR(15) DEFAULT 'aktif' CHECK (durum IN ('aktif','dondurulmus','kapali'))
);

-- ---------------------------------------------------------------------
-- Kartlar
-- ---------------------------------------------------------------------
CREATE TABLE kartlar (
    kart_id        SERIAL PRIMARY KEY,
    hesap_id       INT NOT NULL REFERENCES hesaplar(hesap_id),
    kart_no        CHAR(16) NOT NULL,
    kart_tipi      VARCHAR(15) CHECK (kart_tipi IN ('banka','kredi')),
    son_kullanma   DATE,
    durum          VARCHAR(15) DEFAULT 'aktif'
);

-- ---------------------------------------------------------------------
-- İşlemler  (BÜYÜK TABLO - performans analizinin kalbi)
-- ---------------------------------------------------------------------
CREATE TABLE islemler (
    islem_id        BIGSERIAL PRIMARY KEY,
    hesap_id        INT NOT NULL,                 -- kasıtlı: indeks yok (sonra eklenecek)
    islem_tipi      VARCHAR(15) NOT NULL,         -- para_yatirma, para_cekme, havale, eft, odeme
    tutar           NUMERIC(12,2) NOT NULL,
    bakiye_sonrasi  NUMERIC(14,2),
    karsi_iban      VARCHAR(34),
    aciklama        VARCHAR(200),
    islem_tarihi    TIMESTAMP NOT NULL
);

COMMENT ON TABLE islemler IS 'Tüm para hareketleri - performans testlerinin ana tablosu (milyonlarca satır)';
