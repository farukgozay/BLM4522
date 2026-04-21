-- =====================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 1: Veritabanı ve Tablo Oluşturma
-- =====================================================

-- Veritabanı oluşturma
CREATE DATABASE eticaret_db
    WITH ENCODING 'UTF8'
    LC_COLLATE = 'tr_TR.UTF-8'
    LC_CTYPE = 'tr_TR.UTF-8'
    TEMPLATE = template0;

-- Veritabanına bağlandıktan sonra çalıştırın:
\c eticaret_db;

-- Müşteriler tablosu
CREATE TABLE musteriler (
    musteri_id SERIAL PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefon VARCHAR(15),
    adres TEXT,
    sehir VARCHAR(50),
    kayit_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    aktif BOOLEAN DEFAULT TRUE
);

-- Kategoriler tablosu
CREATE TABLE kategoriler (
    kategori_id SERIAL PRIMARY KEY,
    kategori_adi VARCHAR(100) NOT NULL,
    aciklama TEXT,
    ust_kategori_id INT REFERENCES kategoriler(kategori_id)
);

-- Ürünler tablosu
CREATE TABLE urunler (
    urun_id SERIAL PRIMARY KEY,
    urun_adi VARCHAR(200) NOT NULL,
    kategori_id INT REFERENCES kategoriler(kategori_id),
    fiyat DECIMAL(10, 2) NOT NULL CHECK (fiyat > 0),
    stok_miktari INT DEFAULT 0 CHECK (stok_miktari >= 0),
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Siparişler tablosu
CREATE TABLE siparisler (
    siparis_id SERIAL PRIMARY KEY,
    musteri_id INT REFERENCES musteriler(musteri_id),
    siparis_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    toplam_tutar DECIMAL(12, 2),
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'hazirlaniyor', 'kargoda', 'teslim_edildi', 'iptal')),
    kargo_adresi TEXT,
    notlar TEXT
);

-- Sipariş detayları tablosu
CREATE TABLE siparis_detaylari (
    detay_id SERIAL PRIMARY KEY,
    siparis_id INT REFERENCES siparisler(siparis_id) ON DELETE CASCADE,
    urun_id INT REFERENCES urunler(urun_id),
    miktar INT NOT NULL CHECK (miktar > 0),
    birim_fiyat DECIMAL(10, 2) NOT NULL,
    toplam DECIMAL(12, 2) GENERATED ALWAYS AS (miktar * birim_fiyat) STORED
);

-- Ödeme tablosu
CREATE TABLE odemeler (
    odeme_id SERIAL PRIMARY KEY,
    siparis_id INT REFERENCES siparisler(siparis_id),
    odeme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tutar DECIMAL(12, 2) NOT NULL,
    odeme_yontemi VARCHAR(30) CHECK (odeme_yontemi IN ('kredi_karti', 'havale', 'kapida_odeme')),
    durum VARCHAR(20) DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'reddedildi', 'iade'))
);

-- Yedekleme log tablosu (yedekleme işlemlerini takip etmek için)
CREATE TABLE yedekleme_log (
    log_id SERIAL PRIMARY KEY,
    yedek_tipi VARCHAR(20) NOT NULL,
    dosya_adi VARCHAR(500),
    baslangic_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    bitis_zamani TIMESTAMP,
    boyut_mb DECIMAL(10, 2),
    durum VARCHAR(20) DEFAULT 'baslatildi',
    hata_mesaji TEXT
);

-- İndeksler
CREATE INDEX idx_musteriler_email ON musteriler(email);
CREATE INDEX idx_musteriler_sehir ON musteriler(sehir);
CREATE INDEX idx_urunler_kategori ON urunler(kategori_id);
CREATE INDEX idx_siparisler_musteri ON siparisler(musteri_id);
CREATE INDEX idx_siparisler_tarih ON siparisler(siparis_tarihi);
CREATE INDEX idx_siparis_detay_siparis ON siparis_detaylari(siparis_id);
CREATE INDEX idx_odemeler_siparis ON odemeler(siparis_id);

COMMENT ON TABLE musteriler IS 'E-ticaret platformu müşteri bilgileri';
COMMENT ON TABLE urunler IS 'Satışa sunulan ürünlerin bilgileri';
COMMENT ON TABLE siparisler IS 'Müşteri siparişleri ana tablosu';
COMMENT ON TABLE siparis_detaylari IS 'Siparişlerdeki ürün kalemleri';
COMMENT ON TABLE odemeler IS 'Sipariş ödeme kayıtları';
COMMENT ON TABLE yedekleme_log IS 'Yedekleme işlemleri log tablosu';
