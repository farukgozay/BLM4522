-- =====================================================
-- PROJE 5: Veri Temizleme ve ETL Süreçleri
-- Adım 1: Staging Tabloları Oluşturma
-- =====================================================

CREATE DATABASE etl_db
    WITH ENCODING 'UTF8'
    TEMPLATE = template0;

-- etl_db'ye bağlanın:
\c etl_db;

-- Staging şeması: ham veriler buraya yüklenecek
CREATE SCHEMA staging;

-- Hedef şeması: temiz veriler buraya aktarılacak
CREATE SCHEMA hedef;

-- Log şeması: ETL süreç logları
CREATE SCHEMA etl_log;

-- ========================
-- STAGING TABLOLARI (ham veri yapısı, kısıtlama yok)
-- ========================

CREATE TABLE staging.raw_musteriler (
    musteri_id TEXT,
    ad TEXT,
    soyad TEXT,
    email TEXT,
    telefon TEXT,
    dogum_tarihi TEXT,
    sehir TEXT,
    cinsiyet TEXT,
    kayit_tarihi TEXT
);

CREATE TABLE staging.raw_siparisler (
    siparis_id TEXT,
    musteri_id TEXT,
    urun_adi TEXT,
    miktar TEXT,
    birim_fiyat TEXT,
    toplam_tutar TEXT,
    siparis_tarihi TEXT,
    durum TEXT,
    kargo_sehir TEXT
);

CREATE TABLE staging.raw_urunler (
    urun_id TEXT,
    urun_adi TEXT,
    kategori TEXT,
    fiyat TEXT,
    stok TEXT,
    birim TEXT,
    agirlik_kg TEXT,
    renk TEXT
);

-- ========================
-- HEDEF TABLOLARI (temiz veri yapısı, kısıtlamalar mevcut)
-- ========================

CREATE TABLE hedef.musteriler (
    musteri_id INT PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    telefon VARCHAR(15),
    dogum_tarihi DATE,
    sehir VARCHAR(50),
    cinsiyet VARCHAR(10) CHECK (cinsiyet IN ('Erkek', 'Kadın')),
    kayit_tarihi DATE
);

CREATE TABLE hedef.urunler (
    urun_id VARCHAR(10) PRIMARY KEY,
    urun_adi VARCHAR(200) NOT NULL,
    kategori VARCHAR(50) NOT NULL,
    fiyat DECIMAL(10,2) NOT NULL CHECK (fiyat > 0),
    stok INT DEFAULT 0 CHECK (stok >= 0),
    birim VARCHAR(10) DEFAULT 'Adet',
    agirlik_kg DECIMAL(6,3),
    renk VARCHAR(30)
);

CREATE TABLE hedef.siparisler (
    siparis_id INT PRIMARY KEY,
    musteri_id INT REFERENCES hedef.musteriler(musteri_id),
    urun_adi VARCHAR(200),
    miktar INT CHECK (miktar > 0),
    birim_fiyat DECIMAL(10,2) CHECK (birim_fiyat > 0),
    toplam_tutar DECIMAL(12,2),
    siparis_tarihi DATE,
    durum VARCHAR(20) CHECK (durum IN ('Beklemede', 'Kargoda', 'Teslim Edildi', 'İptal')),
    kargo_sehir VARCHAR(50)
);

-- ========================
-- ETL LOG TABLOSU
-- ========================

CREATE TABLE etl_log.islem_log (
    log_id SERIAL PRIMARY KEY,
    islem_adi VARCHAR(100),
    tablo_adi VARCHAR(100),
    baslangic TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    bitis TIMESTAMP,
    etkilenen_kayit INT,
    durum VARCHAR(20),
    detay TEXT
);

CREATE TABLE etl_log.hata_log (
    hata_id SERIAL PRIMARY KEY,
    kaynak_tablo VARCHAR(100),
    kaynak_satir TEXT,
    hata_tipi VARCHAR(50),
    hata_aciklama TEXT,
    tespit_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
