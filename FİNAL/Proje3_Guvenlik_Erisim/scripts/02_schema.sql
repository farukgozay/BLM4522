-- =====================================================================
-- PROJE 3 - Dosya 02: Şema (guvenlik_db)
-- 'guvenlik_db' veritabanına bağlıyken çalıştırın.
-- =====================================================================

-- pgcrypto: şifreleme ve hash fonksiyonları (TDE/şifreleme demosu için)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS audit_log        CASCADE;
DROP TABLE IF EXISTS kartlar          CASCADE;
DROP TABLE IF EXISTS hesaplar         CASCADE;
DROP TABLE IF EXISTS sifreli_kayitlar CASCADE;
DROP TABLE IF EXISTS kullanicilar     CASCADE;
DROP TABLE IF EXISTS musteriler       CASCADE;

-- ---------------------------------------------------------------------
-- Müşteriler (hassas alan: tc_kimlik)
-- ---------------------------------------------------------------------
CREATE TABLE musteriler (
    musteri_id   SERIAL PRIMARY KEY,
    ad           VARCHAR(50) NOT NULL,
    soyad        VARCHAR(50) NOT NULL,
    tc_kimlik    CHAR(11) NOT NULL,          -- HASSAS
    telefon      VARCHAR(20),
    dogum_tarihi DATE,
    sehir        VARCHAR(50)
);

-- ---------------------------------------------------------------------
-- Hesaplar (hassas alan: bakiye)
-- ---------------------------------------------------------------------
CREATE TABLE hesaplar (
    hesap_id   SERIAL PRIMARY KEY,
    musteri_id INT REFERENCES musteriler(musteri_id),
    iban       VARCHAR(34) NOT NULL,
    bakiye     NUMERIC(14,2) DEFAULT 0       -- HASSAS
);

-- ---------------------------------------------------------------------
-- Kartlar (hassas alanlar: kart_no, cvv)
-- ---------------------------------------------------------------------
CREATE TABLE kartlar (
    kart_id      SERIAL PRIMARY KEY,
    musteri_id   INT REFERENCES musteriler(musteri_id),
    kart_no      CHAR(16) NOT NULL,          -- HASSAS
    cvv          CHAR(3)  NOT NULL,          -- HASSAS
    son_kullanma DATE
);

-- ---------------------------------------------------------------------
-- Uygulama kullanıcıları (internet bankacılığı giriş hesapları)
-- SQL Injection ve parola hash demosu için.
-- ---------------------------------------------------------------------
CREATE TABLE kullanicilar (
    kullanici_id  SERIAL PRIMARY KEY,
    kullanici_adi VARCHAR(40) UNIQUE NOT NULL,
    parola_hash   TEXT NOT NULL,             -- DÜZ PAROLA ASLA SAKLANMAZ
    rol           VARCHAR(20) DEFAULT 'musteri',
    son_giris     TIMESTAMP
);

-- ---------------------------------------------------------------------
-- Şifreli kayıtlar (pgcrypto ile sütun bazlı şifreleme demosu)
-- tc_kimlik ve kart_no burada ŞİFRELİ (bytea) olarak tutulur.
-- ---------------------------------------------------------------------
CREATE TABLE sifreli_kayitlar (
    id              SERIAL PRIMARY KEY,
    musteri_adi     VARCHAR(100) NOT NULL,
    tc_sifreli      BYTEA NOT NULL,          -- pgp_sym_encrypt çıktısı
    kart_no_sifreli BYTEA NOT NULL
);

\echo '### guvenlik_db semasi olusturuldu (pgcrypto etkin) ###'
