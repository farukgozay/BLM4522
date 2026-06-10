-- =====================================================================
-- PROJE 3 - Dosya 03: Örnek veri (guvenlik_db)
-- Tamamen sentetik veri. Gerçek kişi bilgisi içermez.
-- =====================================================================

-- Müşteriler (50 adet)
INSERT INTO musteriler (ad, soyad, tc_kimlik, telefon, dogum_tarihi, sehir)
SELECT
    (ARRAY['Ahmet','Mehmet','Ayse','Fatma','Can','Zeynep','Emre','Merve','Burak','Seda'])[1+floor(random()*10)::int],
    (ARRAY['Yilmaz','Kaya','Demir','Sahin','Celik','Yildiz','Aydin','Arslan','Dogan','Kilic'])[1+floor(random()*10)::int],
    lpad((10000000000 + floor(random()*89999999999))::bigint::text, 11, '0'),
    '05' || lpad(floor(random()*100000000)::int::text, 8, '0'),
    DATE '1960-01-01' + (floor(random()*18000))::int,
    (ARRAY['Istanbul','Ankara','Izmir','Bursa','Antalya'])[1+floor(random()*5)::int]
FROM generate_series(1,50) g;

-- Hesaplar (her müşteriye 1-2 hesap)
INSERT INTO hesaplar (musteri_id, iban, bakiye)
SELECT
    1 + floor(random()*50)::int,
    'TR' || lpad((floor(random()*1e12))::bigint::text, 24, '0'),
    round((random()*500000)::numeric, 2)
FROM generate_series(1,70) g;

-- Kartlar
INSERT INTO kartlar (musteri_id, kart_no, cvv, son_kullanma)
SELECT
    1 + floor(random()*50)::int,
    lpad((floor(random()*1e15))::bigint::text, 16, '0'),
    lpad(floor(random()*1000)::int::text, 3, '0'),
    DATE '2027-01-01' + (floor(random()*1000))::int
FROM generate_series(1,50) g;

-- ---------------------------------------------------------------------
-- Uygulama kullanıcıları - parolalar bcrypt ile HASH'lenerek saklanır
-- (crypt + gen_salt('bf')). Düz parola asla tutulmaz!
-- ---------------------------------------------------------------------
INSERT INTO kullanicilar (kullanici_adi, parola_hash, rol) VALUES
  ('ahmet',  crypt('sifre123',  gen_salt('bf')), 'musteri'),
  ('mehmet', crypt('parolam456', gen_salt('bf')), 'musteri'),
  ('admin',  crypt('Admin*2025', gen_salt('bf')), 'yonetici');

\echo '### Ornek veri yuklendi ###'
SELECT 'musteriler' AS tablo, count(*) FROM musteriler
UNION ALL SELECT 'hesaplar', count(*) FROM hesaplar
UNION ALL SELECT 'kartlar', count(*) FROM kartlar
UNION ALL SELECT 'kullanicilar', count(*) FROM kullanicilar;

-- Parola hash'inin nasıl göründüğünü göster (bcrypt $2a$...)
\echo '### Parolalar HASH olarak saklaniyor (duz metin degil): ###'
SELECT kullanici_adi, left(parola_hash, 30) || '...' AS parola_hash_ornegi FROM kullanicilar;
