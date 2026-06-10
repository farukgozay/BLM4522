-- =====================================================================
-- PROJE 7 - Dosya 02: Örnek veri (yedekleme_db)
-- Yedeklenecek iş verisi. Tamamen sentetik.
-- =====================================================================

INSERT INTO musteriler (ad, soyad, sehir)
SELECT
    (ARRAY['Ahmet','Mehmet','Ayse','Fatma','Can','Zeynep','Emre','Merve'])[1+floor(random()*8)::int],
    (ARRAY['Yilmaz','Kaya','Demir','Sahin','Celik','Yildiz','Aydin','Arslan'])[1+floor(random()*8)::int],
    (ARRAY['Istanbul','Ankara','Izmir','Bursa','Antalya'])[1+floor(random()*5)::int]
FROM generate_series(1,5000);

INSERT INTO islemler (musteri_id, tutar, islem_tarihi)
SELECT
    1 + floor(random()*5000)::int,
    round((random()*10000)::numeric, 2),
    now() - (floor(random()*365) || ' days')::interval
FROM generate_series(1,20000);

\echo '### Ornek veri yuklendi ###'
SELECT 'musteriler' AS tablo, count(*) FROM musteriler
UNION ALL SELECT 'islemler', count(*) FROM islemler;
