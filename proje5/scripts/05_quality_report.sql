-- =====================================================
-- PROJE 5: Veri Temizleme ve ETL Süreçleri
-- Adım 5: Veri Kalitesi Raporları
-- =====================================================

-- ================================================================
-- RAPOR 1: ETL SÜREÇ ÖZETİ
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  ETL SUREC OZET RAPORU' AS rapor;
SELECT '========================================' AS rapor;

SELECT 
    islem_adi,
    tablo_adi,
    durum,
    etkilenen_kayit,
    baslangic,
    bitis,
    ROUND(EXTRACT(EPOCH FROM (bitis - baslangic)), 2) AS sure_saniye
FROM etl_log.islem_log
ORDER BY log_id;

-- ================================================================
-- RAPOR 2: KAYNAK vs HEDEF KARŞILAŞTIRMASI
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  KAYNAK vs HEDEF KARSILASTIRMASI' AS rapor;
SELECT '========================================' AS rapor;

SELECT 
    'Müşteriler' AS veri_seti,
    (SELECT COUNT(*) FROM staging.raw_musteriler) AS kaynak_kayit,
    (SELECT COUNT(*) FROM hedef.musteriler) AS hedef_kayit,
    (SELECT COUNT(*) FROM staging.raw_musteriler) - (SELECT COUNT(*) FROM hedef.musteriler) AS elenen_kayit,
    ROUND(
        (SELECT COUNT(*) FROM hedef.musteriler)::DECIMAL / 
        NULLIF((SELECT COUNT(*) FROM staging.raw_musteriler), 0) * 100, 1
    ) AS gecis_orani_yuzde

UNION ALL

SELECT 
    'Ürünler',
    (SELECT COUNT(*) FROM staging.raw_urunler),
    (SELECT COUNT(*) FROM hedef.urunler),
    (SELECT COUNT(*) FROM staging.raw_urunler) - (SELECT COUNT(*) FROM hedef.urunler),
    ROUND(
        (SELECT COUNT(*) FROM hedef.urunler)::DECIMAL / 
        NULLIF((SELECT COUNT(*) FROM staging.raw_urunler), 0) * 100, 1
    )

UNION ALL

SELECT 
    'Siparişler',
    (SELECT COUNT(*) FROM staging.raw_siparisler),
    (SELECT COUNT(*) FROM hedef.siparisler),
    (SELECT COUNT(*) FROM staging.raw_siparisler) - (SELECT COUNT(*) FROM hedef.siparisler),
    ROUND(
        (SELECT COUNT(*) FROM hedef.siparisler)::DECIMAL / 
        NULLIF((SELECT COUNT(*) FROM staging.raw_siparisler), 0) * 100, 1
    );

-- ================================================================
-- RAPOR 3: HATA DAGILIMI
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  HATA DAGILIM RAPORU' AS rapor;
SELECT '========================================' AS rapor;

SELECT 
    kaynak_tablo,
    hata_tipi,
    COUNT(*) AS hata_sayisi,
    ROUND(COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM etl_log.hata_log) * 100, 1) AS yuzde
FROM etl_log.hata_log
GROUP BY kaynak_tablo, hata_tipi
ORDER BY kaynak_tablo, hata_sayisi DESC;

SELECT 'Toplam tespit edilen hata:' AS bilgi, COUNT(*) AS sayi FROM etl_log.hata_log;

-- ================================================================
-- RAPOR 4: MÜŞTERİ VERİ KALİTESİ
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  MUSTERI VERI KALITESI' AS rapor;
SELECT '========================================' AS rapor;

SELECT
    COUNT(*) AS toplam_musteri,
    COUNT(*) FILTER (WHERE email IS NOT NULL) AS email_dolu,
    COUNT(*) FILTER (WHERE telefon IS NOT NULL) AS telefon_dolu,
    COUNT(*) FILTER (WHERE dogum_tarihi IS NOT NULL) AS dogum_tarihi_dolu,
    COUNT(*) FILTER (WHERE sehir IS NOT NULL) AS sehir_dolu,
    COUNT(*) FILTER (WHERE cinsiyet IS NOT NULL) AS cinsiyet_dolu,
    ROUND(COUNT(*) FILTER (WHERE email IS NOT NULL)::DECIMAL / COUNT(*) * 100, 1) AS email_doluluk_yuzde,
    ROUND(COUNT(*) FILTER (WHERE telefon IS NOT NULL)::DECIMAL / COUNT(*) * 100, 1) AS telefon_doluluk_yuzde
FROM hedef.musteriler;

-- Şehir dağılımı
SELECT sehir, COUNT(*) AS musteri_sayisi
FROM hedef.musteriler
WHERE sehir IS NOT NULL
GROUP BY sehir
ORDER BY musteri_sayisi DESC
LIMIT 10;

-- Cinsiyet dağılımı
SELECT cinsiyet, COUNT(*) AS sayi,
       ROUND(COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM hedef.musteriler) * 100, 1) AS yuzde
FROM hedef.musteriler
WHERE cinsiyet IS NOT NULL
GROUP BY cinsiyet;

-- ================================================================
-- RAPOR 5: ÜRÜN VERİ KALİTESİ
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  URUN VERI KALITESI' AS rapor;
SELECT '========================================' AS rapor;

SELECT
    COUNT(*) AS toplam_urun,
    COUNT(*) FILTER (WHERE fiyat IS NOT NULL) AS fiyat_dolu,
    COUNT(*) FILTER (WHERE stok > 0) AS stokta_olan,
    ROUND(AVG(fiyat), 2) AS ortalama_fiyat,
    MIN(fiyat) AS min_fiyat,
    MAX(fiyat) AS max_fiyat,
    SUM(stok) AS toplam_stok
FROM hedef.urunler;

-- Kategori dağılımı
SELECT kategori, COUNT(*) AS urun_sayisi,
       ROUND(AVG(fiyat), 2) AS ort_fiyat,
       SUM(stok) AS toplam_stok
FROM hedef.urunler
GROUP BY kategori
ORDER BY urun_sayisi DESC;

-- ================================================================
-- RAPOR 6: SİPARİŞ VERİ KALİTESİ
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  SIPARIS VERI KALITESI' AS rapor;
SELECT '========================================' AS rapor;

SELECT
    COUNT(*) AS toplam_siparis,
    COUNT(DISTINCT musteri_id) AS benzersiz_musteri,
    ROUND(AVG(toplam_tutar), 2) AS ort_siparis_tutari,
    SUM(toplam_tutar) AS toplam_ciro,
    MIN(siparis_tarihi) AS ilk_siparis,
    MAX(siparis_tarihi) AS son_siparis
FROM hedef.siparisler;

-- Durum dağılımı
SELECT durum, COUNT(*) AS sayi,
       ROUND(COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM hedef.siparisler) * 100, 1) AS yuzde,
       ROUND(AVG(toplam_tutar), 2) AS ort_tutar
FROM hedef.siparisler
GROUP BY durum
ORDER BY sayi DESC;

-- Aylık sipariş trendi
SELECT 
    TO_CHAR(siparis_tarihi, 'YYYY-MM') AS ay,
    COUNT(*) AS siparis_sayisi,
    ROUND(SUM(toplam_tutar), 2) AS aylik_ciro
FROM hedef.siparisler
WHERE siparis_tarihi IS NOT NULL
GROUP BY TO_CHAR(siparis_tarihi, 'YYYY-MM')
ORDER BY ay;

-- En çok sipariş edilen ürünler
SELECT urun_adi, COUNT(*) AS siparis_adedi, SUM(miktar) AS toplam_adet,
       ROUND(SUM(toplam_tutar), 2) AS toplam_gelir
FROM hedef.siparisler
GROUP BY urun_adi
ORDER BY toplam_gelir DESC
LIMIT 10;

-- ================================================================
-- RAPOR 7: GENEL VERİ KALİTESİ SKORU
-- ================================================================

SELECT '========================================' AS rapor;
SELECT '  GENEL VERI KALITESI SKORU' AS rapor;
SELECT '========================================' AS rapor;

WITH kalite AS (
    SELECT
        (SELECT ROUND(COUNT(*) FILTER (WHERE email IS NOT NULL)::DECIMAL / COUNT(*) * 100, 0) FROM hedef.musteriler) AS musteri_email,
        (SELECT ROUND(COUNT(*) FILTER (WHERE telefon IS NOT NULL)::DECIMAL / COUNT(*) * 100, 0) FROM hedef.musteriler) AS musteri_telefon,
        (SELECT ROUND(COUNT(*) FILTER (WHERE fiyat IS NOT NULL)::DECIMAL / COUNT(*) * 100, 0) FROM hedef.urunler) AS urun_fiyat,
        (SELECT ROUND(COUNT(*) FILTER (WHERE toplam_tutar IS NOT NULL)::DECIMAL / COUNT(*) * 100, 0) FROM hedef.siparisler) AS siparis_tutar
)
SELECT 
    musteri_email AS "Müşteri Email Doluluk %",
    musteri_telefon AS "Müşteri Telefon Doluluk %",
    urun_fiyat AS "Ürün Fiyat Doluluk %",
    siparis_tutar AS "Sipariş Tutar Doluluk %",
    ROUND((musteri_email + musteri_telefon + urun_fiyat + siparis_tutar) / 4.0, 1) AS "Genel Kalite Skoru %"
FROM kalite;
