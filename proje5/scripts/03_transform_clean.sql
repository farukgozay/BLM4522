-- =====================================================
-- PROJE 5: Veri Temizleme ve ETL Süreçleri
-- Adım 3: TRANSFORM — Veri Temizleme ve Dönüştürme
-- =====================================================

-- ================================================================
-- BÖLÜM A: MÜŞTERİ VERİSİ TEMİZLEME
-- ================================================================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('TRANSFORM_MUSTERI', 'staging.raw_musteriler', 'baslatildi');

-- A1: Boş/NULL alan tespiti
INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_musteriler', musteri_id, 'EKSIK_AD', 'Ad alanı boş'
FROM staging.raw_musteriler WHERE TRIM(COALESCE(ad, '')) = '';

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_musteriler', musteri_id, 'EKSIK_SOYAD', 'Soyad alanı boş'
FROM staging.raw_musteriler WHERE TRIM(COALESCE(soyad, '')) = '';

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_musteriler', musteri_id, 'EKSIK_EMAIL', 'Email alanı boş'
FROM staging.raw_musteriler WHERE TRIM(COALESCE(email, '')) = '';

-- A2: Duplike kayıt tespiti (email bazlı)
INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_musteriler', musteri_id, 'DUPLIKE', 'Tekrarlanan email: ' || email
FROM (
    SELECT musteri_id, email,
           ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(email)) ORDER BY musteri_id::INT) AS rn
    FROM staging.raw_musteriler
    WHERE TRIM(COALESCE(email, '')) != ''
) t WHERE rn > 1;

-- A3: Geçersiz email formatı tespiti
INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_musteriler', musteri_id, 'GECERSIZ_EMAIL', 'Geçersiz format: ' || email
FROM staging.raw_musteriler
WHERE email IS NOT NULL 
  AND TRIM(email) != ''
  AND email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- A4: Geçersiz telefon tespiti
INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_musteriler', musteri_id, 'GECERSIZ_TELEFON', 'Geçersiz telefon: ' || telefon
FROM staging.raw_musteriler
WHERE telefon IS NOT NULL 
  AND TRIM(telefon) != ''
  AND telefon !~ '^\+?[0-9\-\s]{10,15}$';

-- A5: Temizlenmiş müşteri verisini oluştur
CREATE TEMP TABLE clean_musteriler AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(TRIM(COALESCE(email, musteri_id))) 
               ORDER BY musteri_id::INT
           ) AS rn
    FROM staging.raw_musteriler
    WHERE TRIM(COALESCE(ad, '')) != ''  -- adı boş olanları çıkar
)
SELECT
    musteri_id::INT,
    
    -- Ad: baş harfi büyük, trim
    INITCAP(TRIM(ad)) AS ad,
    INITCAP(TRIM(soyad)) AS soyad,
    
    -- Email: küçük harfe çevir
    LOWER(TRIM(email)) AS email,
    
    -- Telefon: sadece rakamları al, başına 0 ekle
    CASE 
        WHEN telefon ~ '^[0-9]+$' AND LENGTH(telefon) = 10 THEN '0' || telefon
        WHEN telefon ~ '^0[0-9]{10}$' THEN telefon
        ELSE NULL
    END AS telefon,
    
    -- Doğum tarihi: farklı formatları standartlaştır
    CASE
        WHEN dogum_tarihi ~ '^\d{4}-\d{2}-\d{2}$' THEN dogum_tarihi::DATE
        WHEN dogum_tarihi ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(dogum_tarihi, 'DD/MM/YYYY')
        WHEN dogum_tarihi ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(dogum_tarihi, 'DD.MM.YYYY')
        WHEN dogum_tarihi ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(dogum_tarihi, 'DD-MM-YYYY')
        ELSE NULL
    END AS dogum_tarihi,
    
    -- Şehir: INITCAP
    INITCAP(TRIM(sehir)) AS sehir,
    
    -- Cinsiyet: standartlaştır
    CASE 
        WHEN UPPER(TRIM(cinsiyet)) IN ('ERKEK', 'E') THEN 'Erkek'
        WHEN UPPER(TRIM(cinsiyet)) IN ('KADIN', 'K', 'KADÝN') THEN 'Kadın'
        ELSE NULL
    END AS cinsiyet,
    
    -- Kayıt tarihi
    CASE 
        WHEN kayit_tarihi ~ '^\d{4}-\d{2}-\d{2}$' THEN kayit_tarihi::DATE
        ELSE NULL
    END AS kayit_tarihi

FROM deduplicated
WHERE rn = 1
  AND email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';


-- ================================================================
-- BÖLÜM B: ÜRÜN VERİSİ TEMİZLEME
-- ================================================================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('TRANSFORM_URUN', 'staging.raw_urunler', 'baslatildi');

-- B1: Sorun tespiti
INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_urunler', urun_id, 'EKSIK_URUN_ADI', 'Ürün adı boş'
FROM staging.raw_urunler WHERE TRIM(COALESCE(urun_adi, '')) = '';

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_urunler', urun_id, 'NEGATIF_FIYAT', 'Negatif fiyat: ' || fiyat
FROM staging.raw_urunler WHERE fiyat::DECIMAL < 0;

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_urunler', urun_id, 'NEGATIF_STOK', 'Negatif stok: ' || stok
FROM staging.raw_urunler WHERE stok IS NOT NULL AND TRIM(stok) != '' AND stok::INT < 0;

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_urunler', urun_id, 'GECERSIZ_KATEGORI', 'Bilinmeyen kategori: ' || kategori
FROM staging.raw_urunler 
WHERE UPPER(TRIM(kategori)) NOT IN ('ELEKTRONIK', 'GİYİM', 'GIYIM', 'EV & YAŞAM', 'EV & YASAM', 'SPOR', 'KITAP', 'KİTAP');

-- B2: Temiz ürün verisi
CREATE TEMP TABLE clean_urunler AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(urun_adi)) ORDER BY urun_id) AS rn
    FROM staging.raw_urunler
    WHERE TRIM(COALESCE(urun_adi, '')) != ''
)
SELECT
    urun_id,
    TRIM(urun_adi) AS urun_adi,
    
    -- Kategori standardizasyonu
    CASE UPPER(TRIM(kategori))
        WHEN 'ELEKTRONIK' THEN 'Elektronik'
        WHEN 'GİYİM' THEN 'Giyim'
        WHEN 'GIYIM' THEN 'Giyim'
        WHEN 'EV & YAŞAM' THEN 'Ev & Yaşam'
        WHEN 'EV & YASAM' THEN 'Ev & Yaşam'
        WHEN 'SPOR' THEN 'Spor'
        WHEN 'KITAP' THEN 'Kitap'
        WHEN 'KİTAP' THEN 'Kitap'
        ELSE NULL
    END AS kategori,
    
    -- Fiyat: negatifleri pozitife çevir, sıfırları NULL yap
    CASE 
        WHEN fiyat::DECIMAL <= 0 THEN NULL
        ELSE ABS(fiyat::DECIMAL)
    END AS fiyat,
    
    -- Stok: negatifleri 0 yap
    CASE 
        WHEN stok IS NULL OR TRIM(stok) = '' THEN 0
        WHEN stok::INT < 0 THEN 0
        ELSE stok::INT
    END AS stok,
    
    INITCAP(TRIM(birim)) AS birim,
    
    CASE 
        WHEN agirlik_kg IS NOT NULL AND TRIM(agirlik_kg) != '' THEN agirlik_kg::DECIMAL
        ELSE NULL
    END AS agirlik_kg,
    
    NULLIF(TRIM(renk), '') AS renk

FROM deduplicated
WHERE rn = 1
  AND UPPER(TRIM(kategori)) IN ('ELEKTRONIK', 'GİYİM', 'GIYIM', 'EV & YAŞAM', 'EV & YASAM', 'SPOR', 'KITAP', 'KİTAP');


-- ================================================================
-- BÖLÜM C: SİPARİŞ VERİSİ TEMİZLEME
-- ================================================================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('TRANSFORM_SIPARIS', 'staging.raw_siparisler', 'baslatildi');

-- C1: Sorun tespiti
INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_siparisler', siparis_id, 'EKSIK_MUSTERI', 'Müşteri ID boş'
FROM staging.raw_siparisler WHERE TRIM(COALESCE(musteri_id, '')) = '';

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_siparisler', siparis_id, 'GECERSIZ_MUSTERI', 'Müşteri bulunamadı: ' || musteri_id
FROM staging.raw_siparisler s
WHERE TRIM(COALESCE(musteri_id, '')) != ''
  AND NOT EXISTS (SELECT 1 FROM clean_musteriler m WHERE m.musteri_id = s.musteri_id::INT);

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_siparisler', siparis_id, 'NEGATIF_MIKTAR', 'Negatif miktar: ' || miktar
FROM staging.raw_siparisler WHERE miktar::INT <= 0;

INSERT INTO etl_log.hata_log (kaynak_tablo, kaynak_satir, hata_tipi, hata_aciklama)
SELECT 'raw_siparisler', siparis_id, 'TUTARSIZ_TOPLAM', 
    'Beklenen: ' || (miktar::INT * birim_fiyat::DECIMAL)::TEXT || ' Gelen: ' || toplam_tutar
FROM staging.raw_siparisler
WHERE miktar::INT > 0 
  AND birim_fiyat::DECIMAL > 0
  AND ABS(toplam_tutar::DECIMAL - miktar::INT * birim_fiyat::DECIMAL) > 0.01;

-- C2: Temiz sipariş verisi
CREATE TEMP TABLE clean_siparisler AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY siparis_id 
               ORDER BY siparis_id::INT
           ) AS rn
    FROM staging.raw_siparisler
    WHERE TRIM(COALESCE(musteri_id, '')) != ''
)
SELECT
    siparis_id::INT,
    musteri_id::INT,
    TRIM(urun_adi) AS urun_adi,
    
    CASE WHEN miktar::INT > 0 THEN miktar::INT ELSE NULL END AS miktar,
    
    CASE WHEN birim_fiyat::DECIMAL > 0 THEN birim_fiyat::DECIMAL ELSE NULL END AS birim_fiyat,
    
    -- Toplam tutarı yeniden hesapla
    CASE 
        WHEN miktar::INT > 0 AND birim_fiyat::DECIMAL > 0 
        THEN miktar::INT * birim_fiyat::DECIMAL
        ELSE NULL
    END AS toplam_tutar,
    
    -- Tarih standardizasyonu
    CASE
        WHEN siparis_tarihi ~ '^\d{4}-\d{2}-\d{2}$' THEN siparis_tarihi::DATE
        WHEN siparis_tarihi ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(siparis_tarihi, 'DD/MM/YYYY')
        WHEN siparis_tarihi ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(siparis_tarihi, 'DD-MM-YYYY')
        WHEN siparis_tarihi ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(siparis_tarihi, 'YYYY/MM/DD')
        ELSE NULL
    END AS siparis_tarihi,
    
    -- Durum standardizasyonu
    CASE UPPER(TRIM(REPLACE(COALESCE(durum, ''), '_', ' ')))
        WHEN 'TESLIM EDILDI' THEN 'Teslim Edildi'
        WHEN 'KARGODA' THEN 'Kargoda'
        WHEN 'BEKLEMEDE' THEN 'Beklemede'
        WHEN 'IPTAL' THEN 'İptal'
        WHEN 'İPTAL' THEN 'İptal'
        ELSE 'Beklemede'
    END AS durum,
    
    INITCAP(TRIM(NULLIF(kargo_sehir, 'Bilinmiyor'))) AS kargo_sehir

FROM deduplicated
WHERE rn = 1
  AND miktar::INT > 0
  AND birim_fiyat::DECIMAL > 0;

-- ================================================================
-- Transform log güncelle
-- ================================================================

UPDATE etl_log.islem_log SET bitis = CURRENT_TIMESTAMP, durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM clean_musteriler)
WHERE islem_adi = 'TRANSFORM_MUSTERI' AND bitis IS NULL;

UPDATE etl_log.islem_log SET bitis = CURRENT_TIMESTAMP, durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM clean_urunler)
WHERE islem_adi = 'TRANSFORM_URUN' AND bitis IS NULL;

UPDATE etl_log.islem_log SET bitis = CURRENT_TIMESTAMP, durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM clean_siparisler)
WHERE islem_adi = 'TRANSFORM_SIPARIS' AND bitis IS NULL;

-- Özet
SELECT '--- TRANSFORM OZETI ---' AS bilgi;
SELECT 'clean_musteriler' AS tablo, COUNT(*) AS kayit FROM clean_musteriler
UNION ALL SELECT 'clean_urunler', COUNT(*) FROM clean_urunler
UNION ALL SELECT 'clean_siparisler', COUNT(*) FROM clean_siparisler;

SELECT '--- TESPIT EDILEN HATALAR ---' AS bilgi;
SELECT hata_tipi, COUNT(*) AS adet
FROM etl_log.hata_log
GROUP BY hata_tipi
ORDER BY adet DESC;
