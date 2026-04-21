-- =====================================================
-- PROJE 5: Veri Temizleme ve ETL Süreçleri
-- Adım 2: EXTRACT — CSV Dosyalarından Veri Çekme
-- =====================================================

-- NOT: CSV dosyalarının yolunu kendi sisteminize göre güncelleyin
-- Windows'ta ters slash kullanın ve dosya yolunu tırnak içine alın

-- ========================
-- Müşteri Verilerini Yükleme
-- ========================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('EXTRACT', 'staging.raw_musteriler', 'baslatildi');

\copy staging.raw_musteriler FROM 'raw_customers.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

UPDATE etl_log.islem_log 
SET bitis = CURRENT_TIMESTAMP, 
    durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM staging.raw_musteriler)
WHERE islem_adi = 'EXTRACT' AND tablo_adi = 'staging.raw_musteriler' AND bitis IS NULL;

-- ========================
-- Sipariş Verilerini Yükleme
-- ========================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('EXTRACT', 'staging.raw_siparisler', 'baslatildi');

\copy staging.raw_siparisler FROM 'raw_orders.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

UPDATE etl_log.islem_log 
SET bitis = CURRENT_TIMESTAMP,
    durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM staging.raw_siparisler)
WHERE islem_adi = 'EXTRACT' AND tablo_adi = 'staging.raw_siparisler' AND bitis IS NULL;

-- ========================
-- Ürün Verilerini Yükleme
-- ========================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('EXTRACT', 'staging.raw_urunler', 'baslatildi');

\copy staging.raw_urunler FROM 'raw_products.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

UPDATE etl_log.islem_log 
SET bitis = CURRENT_TIMESTAMP,
    durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM staging.raw_urunler)
WHERE islem_adi = 'EXTRACT' AND tablo_adi = 'staging.raw_urunler' AND bitis IS NULL;

-- ========================
-- Extract Sonuç Kontrolü
-- ========================

SELECT '--- EXTRACT OZETI ---' AS bilgi;

SELECT tablo_adi, etkilenen_kayit, durum, baslangic, bitis
FROM etl_log.islem_log
WHERE islem_adi = 'EXTRACT'
ORDER BY log_id;

SELECT 'raw_musteriler' AS tablo, COUNT(*) AS kayit FROM staging.raw_musteriler
UNION ALL SELECT 'raw_siparisler', COUNT(*) FROM staging.raw_siparisler
UNION ALL SELECT 'raw_urunler', COUNT(*) FROM staging.raw_urunler;
