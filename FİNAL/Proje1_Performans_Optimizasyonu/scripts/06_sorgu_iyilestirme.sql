-- =====================================================================
-- PROJE 1 - Dosya 06: Sorgu İyileştirme
-- PDF gereksinimi: "Uzun süren sorguları analiz etme ve optimize etme."
--
-- Her örnekte: KÖTÜ sorgu (yavaş) -> neden yavaş -> İYİ sorgu (hızlı)
-- EXPLAIN ANALYZE ile süre/plan farkını gösteririz.
-- =====================================================================

\timing on

-- ---------------------------------------------------------------------
-- ÖRNEK 1: Kolon üzerinde fonksiyon kullanımı indeksi devre dışı bırakır
--          (non-sargable -> sargable dönüşümü)
-- ---------------------------------------------------------------------
\echo '### ORNEK 1 - KOTU: CAST(islem_tarihi AS DATE) indeksi kullanamaz ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM islemler
WHERE CAST(islem_tarihi AS DATE) = DATE '2024-06-15';

\echo '### ORNEK 1 - IYI: Aralik kosulu indeksi kullanir (sargable) ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM islemler
WHERE islem_tarihi >= '2024-06-15' AND islem_tarihi < '2024-06-16';

-- ---------------------------------------------------------------------
-- ÖRNEK 2: Korelasyonlu alt sorgu (her satır için tekrar çalışır) yerine JOIN
-- ---------------------------------------------------------------------
\echo '### ORNEK 2 - KOTU: Korelasyonlu alt sorgu ile musteri bakiye toplami ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.musteri_id, m.ad, m.soyad,
       (SELECT COALESCE(sum(h.bakiye),0) FROM hesaplar h WHERE h.musteri_id = m.musteri_id) AS toplam_bakiye
FROM musteriler m
WHERE m.sehir = 'Ankara';

\echo '### ORNEK 2 - IYI: JOIN + GROUP BY ile tek gecis ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.musteri_id, m.ad, m.soyad, COALESCE(sum(h.bakiye),0) AS toplam_bakiye
FROM musteriler m
LEFT JOIN hesaplar h ON h.musteri_id = m.musteri_id
WHERE m.sehir = 'Ankara'
GROUP BY m.musteri_id, m.ad, m.soyad;

-- ---------------------------------------------------------------------
-- ÖRNEK 3: musteriler.sehir üzerinde indeks yokken arama yavaş; indeks ekleyelim.
-- ---------------------------------------------------------------------
\echo '### ORNEK 3 - KOTU: sehir uzerinde indeks yokken arama ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT musteri_id, ad, soyad FROM musteriler WHERE sehir = 'Izmir';

CREATE INDEX idx_musteriler_sehir ON musteriler(sehir);

\echo '### ORNEK 3 - IYI: sehir indeksi sonrasi ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT musteri_id, ad, soyad FROM musteriler WHERE sehir = 'Izmir';

-- ---------------------------------------------------------------------
-- ÖRNEK 4: Sayfalama - büyük OFFSET yerine keyset (seek) yöntemi
-- ---------------------------------------------------------------------
\echo '### ORNEK 4 - KOTU: buyuk OFFSET (1.000.000 satir atlanir) ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT islem_id, hesap_id, tutar FROM islemler
ORDER BY islem_id LIMIT 20 OFFSET 1000000;

\echo '### ORNEK 4 - IYI: keyset pagination (WHERE islem_id > son_id) ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT islem_id, hesap_id, tutar FROM islemler
WHERE islem_id > 1000000
ORDER BY islem_id LIMIT 20;

\timing off
\echo '### Sorgu iyilestirme ornekleri tamamlandi ###'
