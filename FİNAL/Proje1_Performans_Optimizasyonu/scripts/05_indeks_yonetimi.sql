-- =====================================================================
-- PROJE 1 - Dosya 05: İndeks Yönetimi
-- PDF gereksinimi: "Sorgu hızını artırmak için doğru indekslerin
-- kullanımı, gereksiz indekslerin kaldırılması."
--
-- Yöntem: Aynı sorguyu indeks YOKKEN ve VARKEN EXPLAIN (ANALYZE, BUFFERS)
-- ile çalıştırıp Seq Scan -> Index Scan dönüşümünü ve süre farkını gösteririz.
-- =====================================================================

\timing on

-- ---------------------------------------------------------------------
-- TEST 1: Belirli bir hesabın işlemleri  (islemler.hesap_id - indeks YOK)
-- ---------------------------------------------------------------------
\echo '### TEST 1 - INDEKS YOKKEN: hesap_id = 12345 islemleri ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM islemler WHERE hesap_id = 12345;

-- Çözüm: hesap_id üzerine B-tree indeks
CREATE INDEX idx_islemler_hesap ON islemler(hesap_id);

\echo '### TEST 1 - INDEKS EKLENDIKTEN SONRA ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM islemler WHERE hesap_id = 12345;

-- ---------------------------------------------------------------------
-- TEST 2: Tarih aralığı sorgusu  (islemler.islem_tarihi - indeks YOK)
-- ---------------------------------------------------------------------
\echo '### TEST 2 - INDEKS YOKKEN: 2024 yili havale islemleri ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM islemler
WHERE islem_tarihi >= '2024-01-01' AND islem_tarihi < '2025-01-01'
  AND islem_tipi = 'havale';

-- Çözüm: tarih + tip üzerine BİLEŞİK (composite) indeks
CREATE INDEX idx_islemler_tarih_tip ON islemler(islem_tarihi, islem_tipi);

\echo '### TEST 2 - BILESIK INDEKS SONRASI ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM islemler
WHERE islem_tarihi >= '2024-01-01' AND islem_tarihi < '2025-01-01'
  AND islem_tipi = 'havale';

-- ---------------------------------------------------------------------
-- TEST 3: KISMİ (partial) indeks - sadece yüksek tutarlı işlemler
-- Tüm tabloyu indekslemek yerine sadece ilgili satırları indeksleriz:
-- daha küçük indeks, daha hızlı sorgu.
-- ---------------------------------------------------------------------
CREATE INDEX idx_islemler_buyuk_tutar ON islemler(tutar)
WHERE tutar > 10000;

\echo '### TEST 3 - KISMI INDEKS ile yuksek tutarli islemler ###'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM islemler WHERE tutar > 12000 ORDER BY tutar DESC LIMIT 20;

-- ---------------------------------------------------------------------
-- GEREKSİZ İNDEKS YÖNETİMİ
-- ---------------------------------------------------------------------
-- Önce işe yaramayan bir indeks oluşturup (örnek), sonra tespit edip
-- kaldırmayı gösteriyoruz. 'aciklama' üzerinde eşitlik araması yapılmaz,
-- bu yüzden bu indeks gereksizdir ve sadece yer kaplar / yazma maliyeti getirir.
CREATE INDEX idx_islemler_aciklama ON islemler(aciklama);

\echo '### Hic kullanilmayan (idx_scan = 0) indeksler - silme adaylari ###'
SELECT indexrelname AS indeks,
       relname      AS tablo,
       idx_scan     AS kullanim,
       pg_size_pretty(pg_relation_size(indexrelid)) AS boyut
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Gereksiz indeksi kaldır
DROP INDEX idx_islemler_aciklama;
\echo '### idx_islemler_aciklama kaldirildi (gereksiz indeks temizligi) ###'

\timing off

-- Mevcut indekslerin son durumu
\echo '### islemler tablosunun guncel indeksleri ###'
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'islemler';
