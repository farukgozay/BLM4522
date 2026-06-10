-- =====================================================================
-- PROJE 1 - Dosya 03: Büyük veri üretimi (banka_db)
-- "Büyük bir veritabanı üzerinde performans analizi" gereksinimi için.
-- Üretilen hacim:
--    subeler     : 20
--    musteriler  : 50.000
--    personel    : 200
--    hesaplar    : 80.000
--    kartlar     : 60.000
--    islemler    : 2.000.000   <-- performans testlerinin ana tablosu
-- Üretim generate_series + random() ile yapılır (tamamen sentetik veri).
-- =====================================================================

-- 1) ŞUBELER -----------------------------------------------------------
INSERT INTO subeler (sube_adi, sehir, adres, acilis_yili)
SELECT 'Sube-' || g,
       (ARRAY['Istanbul','Ankara','Izmir','Bursa','Antalya','Adana','Konya','Gaziantep','Kayseri','Mersin'])
            [1 + floor(random()*10)::int],
       'Merkez Mah. No:' || g,
       2000 + floor(random()*25)::int
FROM generate_series(1,20) g;

-- 2) MÜŞTERİLER --------------------------------------------------------
INSERT INTO musteriler (ad, soyad, tc_kimlik, email, telefon, dogum_tarihi, sehir)
SELECT
    adlar[1 + floor(random()*array_length(adlar,1))::int],
    soyadlar[1 + floor(random()*array_length(soyadlar,1))::int],
    lpad((10000000000 + floor(random()*89999999999))::bigint::text, 11, '0'),
    'musteri' || g || '@eposta.com',
    '05' || lpad(floor(random()*100000000)::int::text, 8, '0'),
    DATE '1950-01-01' + (floor(random()*22000))::int,
    sehirler[1 + floor(random()*array_length(sehirler,1))::int]
FROM
    (SELECT ARRAY['Ahmet','Mehmet','Ayse','Fatma','Mustafa','Elif','Can','Zeynep','Emre','Merve',
                  'Burak','Seda','Kerem','Derya','Ozan','Buse','Hakan','Ece','Tolga','Gizem'] AS adlar,
            ARRAY['Yilmaz','Kaya','Demir','Sahin','Celik','Yildiz','Yildirim','Ozturk','Aydin','Arslan',
                  'Dogan','Kilic','Aslan','Cetin','Kara','Koc','Kurt','Ozdemir','Simsek','Polat'] AS soyadlar,
            ARRAY['Istanbul','Ankara','Izmir','Bursa','Antalya','Adana','Konya','Eskisehir','Trabzon','Samsun'] AS sehirler
    ) veri,
    generate_series(1,50000) g;

-- 3) PERSONEL ----------------------------------------------------------
INSERT INTO personel (sube_id, ad, soyad, rol, maas, ise_giris)
SELECT
    1 + floor(random()*20)::int,
    'Personel' || g,
    'Soyad' || g,
    (ARRAY['gise','uzman','mudur','operasyon','musteri_temsilcisi'])[1 + floor(random()*5)::int],
    25000 + floor(random()*60000)::int,
    DATE '2010-01-01' + (floor(random()*5000))::int
FROM generate_series(1,200) g;

-- 4) HESAPLAR ----------------------------------------------------------
INSERT INTO hesaplar (musteri_id, sube_id, iban, hesap_tipi, bakiye, para_birimi, acilis_tarihi, durum)
SELECT
    1 + floor(random()*50000)::int,
    1 + floor(random()*20)::int,
    'TR' || lpad((floor(random()*1e12))::bigint::text, 24, '0'),
    (ARRAY['vadesiz','vadeli','kredi','altin'])[1 + floor(random()*4)::int],
    round((random()*250000)::numeric, 2),
    'TRY',
    DATE '2015-01-01' + (floor(random()*3500))::int,
    (ARRAY['aktif','aktif','aktif','dondurulmus','kapali'])[1 + floor(random()*5)::int]
FROM generate_series(1,80000) g;

-- 5) KARTLAR -----------------------------------------------------------
INSERT INTO kartlar (hesap_id, kart_no, kart_tipi, son_kullanma, durum)
SELECT
    1 + floor(random()*80000)::int,
    lpad((floor(random()*1e15))::bigint::text, 16, '0'),
    (ARRAY['banka','kredi'])[1 + floor(random()*2)::int],
    DATE '2026-01-01' + (floor(random()*1500))::int,
    'aktif'
FROM generate_series(1,60000) g;

-- 6) İŞLEMLER (2 MİLYON SATIR) ----------------------------------------
-- En maliyetli adım. Bilgisayara göre ~20-60 sn sürebilir.
INSERT INTO islemler (hesap_id, islem_tipi, tutar, bakiye_sonrasi, karsi_iban, aciklama, islem_tarihi)
SELECT
    1 + floor(random()*80000)::int,
    (ARRAY['para_yatirma','para_cekme','havale','eft','odeme'])[1 + floor(random()*5)::int],
    round((random()*15000)::numeric, 2),
    round((random()*200000)::numeric, 2),
    'TR' || lpad((floor(random()*1e12))::bigint::text, 24, '0'),
    'Otomatik uretilen islem #' || g,
    TIMESTAMP '2022-01-01' + (random() * (TIMESTAMP '2025-12-31' - TIMESTAMP '2022-01-01'))
FROM generate_series(1,2000000) g;

-- İstatistikleri güncelle (planlayıcının doğru karar vermesi için)
ANALYZE;

-- Üretim özeti
SELECT 'subeler'    AS tablo, count(*) FROM subeler
UNION ALL SELECT 'musteriler', count(*) FROM musteriler
UNION ALL SELECT 'personel',   count(*) FROM personel
UNION ALL SELECT 'hesaplar',   count(*) FROM hesaplar
UNION ALL SELECT 'kartlar',    count(*) FROM kartlar
UNION ALL SELECT 'islemler',   count(*) FROM islemler;
