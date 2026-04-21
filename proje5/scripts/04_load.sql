-- =====================================================
-- PROJE 5: Veri Temizleme ve ETL Süreçleri
-- Adım 4: LOAD — Temiz Verileri Hedef Tablolara Yükleme
-- =====================================================

-- ========================
-- MÜŞTERİ VERİSİ YÜKLEME
-- ========================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('LOAD', 'hedef.musteriler', 'baslatildi');

INSERT INTO hedef.musteriler (musteri_id, ad, soyad, email, telefon, dogum_tarihi, sehir, cinsiyet, kayit_tarihi)
SELECT musteri_id, ad, soyad, email, telefon, dogum_tarihi, sehir, cinsiyet, kayit_tarihi
FROM clean_musteriler
ON CONFLICT (musteri_id) DO UPDATE SET
    ad = EXCLUDED.ad,
    soyad = EXCLUDED.soyad,
    email = EXCLUDED.email,
    telefon = EXCLUDED.telefon,
    dogum_tarihi = EXCLUDED.dogum_tarihi,
    sehir = EXCLUDED.sehir,
    cinsiyet = EXCLUDED.cinsiyet,
    kayit_tarihi = EXCLUDED.kayit_tarihi;

UPDATE etl_log.islem_log SET bitis = CURRENT_TIMESTAMP, durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM hedef.musteriler)
WHERE islem_adi = 'LOAD' AND tablo_adi = 'hedef.musteriler' AND bitis IS NULL;

-- ========================
-- ÜRÜN VERİSİ YÜKLEME
-- ========================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('LOAD', 'hedef.urunler', 'baslatildi');

INSERT INTO hedef.urunler (urun_id, urun_adi, kategori, fiyat, stok, birim, agirlik_kg, renk)
SELECT urun_id, urun_adi, kategori, fiyat, stok, birim, agirlik_kg, renk
FROM clean_urunler
WHERE kategori IS NOT NULL AND fiyat IS NOT NULL
ON CONFLICT (urun_id) DO UPDATE SET
    urun_adi = EXCLUDED.urun_adi,
    kategori = EXCLUDED.kategori,
    fiyat = EXCLUDED.fiyat,
    stok = EXCLUDED.stok,
    birim = EXCLUDED.birim,
    agirlik_kg = EXCLUDED.agirlik_kg,
    renk = EXCLUDED.renk;

UPDATE etl_log.islem_log SET bitis = CURRENT_TIMESTAMP, durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM hedef.urunler)
WHERE islem_adi = 'LOAD' AND tablo_adi = 'hedef.urunler' AND bitis IS NULL;

-- ========================
-- SİPARİŞ VERİSİ YÜKLEME
-- ========================

INSERT INTO etl_log.islem_log (islem_adi, tablo_adi, durum)
VALUES ('LOAD', 'hedef.siparisler', 'baslatildi');

INSERT INTO hedef.siparisler (siparis_id, musteri_id, urun_adi, miktar, birim_fiyat, toplam_tutar, siparis_tarihi, durum, kargo_sehir)
SELECT s.siparis_id, s.musteri_id, s.urun_adi, s.miktar, s.birim_fiyat, s.toplam_tutar, 
       s.siparis_tarihi, s.durum, s.kargo_sehir
FROM clean_siparisler s
INNER JOIN hedef.musteriler m ON s.musteri_id = m.musteri_id
ON CONFLICT (siparis_id) DO UPDATE SET
    musteri_id = EXCLUDED.musteri_id,
    urun_adi = EXCLUDED.urun_adi,
    miktar = EXCLUDED.miktar,
    birim_fiyat = EXCLUDED.birim_fiyat,
    toplam_tutar = EXCLUDED.toplam_tutar,
    siparis_tarihi = EXCLUDED.siparis_tarihi,
    durum = EXCLUDED.durum,
    kargo_sehir = EXCLUDED.kargo_sehir;

UPDATE etl_log.islem_log SET bitis = CURRENT_TIMESTAMP, durum = 'tamamlandi',
    etkilenen_kayit = (SELECT COUNT(*) FROM hedef.siparisler)
WHERE islem_adi = 'LOAD' AND tablo_adi = 'hedef.siparisler' AND bitis IS NULL;

-- ========================
-- LOAD SONUÇ KONTROLÜ
-- ========================

SELECT '--- LOAD OZETI ---' AS bilgi;

SELECT 'hedef.musteriler' AS tablo, COUNT(*) AS kayit FROM hedef.musteriler
UNION ALL SELECT 'hedef.urunler', COUNT(*) FROM hedef.urunler
UNION ALL SELECT 'hedef.siparisler', COUNT(*) FROM hedef.siparisler;

-- Veri bütünlüğü kontrolü
SELECT '--- BUTUNLUK KONTROLU ---' AS bilgi;

SELECT 'Musteri FK ihlali' AS kontrol, COUNT(*) AS sorunlu
FROM hedef.siparisler s
LEFT JOIN hedef.musteriler m ON s.musteri_id = m.musteri_id
WHERE m.musteri_id IS NULL;

-- Hedef tablolardaki örnek veriler
SELECT '--- ORNEK MUSTERI VERISI ---' AS bilgi;
SELECT * FROM hedef.musteriler LIMIT 5;

SELECT '--- ORNEK URUN VERISI ---' AS bilgi;
SELECT * FROM hedef.urunler LIMIT 5;

SELECT '--- ORNEK SIPARIS VERISI ---' AS bilgi;
SELECT * FROM hedef.siparisler LIMIT 5;
