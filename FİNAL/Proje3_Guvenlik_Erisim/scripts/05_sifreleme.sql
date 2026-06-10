-- =====================================================================
-- PROJE 3 - Dosya 05: Veri Şifreleme
-- PDF gereksinimi: "Veritabanındaki hassas bilgilerin şifrelenmesi
-- (örneğin, TDE - Transparent Data Encryption)."
--
-- PostgreSQL'de community sürümde TDE yoktur; bunun yerine pgcrypto ile
-- SÜTUN BAZLI şifreleme kullanırız (daha güçlü: veri uygulama katmanından
-- bile şifreli gelir).
--   - pgp_sym_encrypt / pgp_sym_decrypt : simetrik şifreleme (AES)
--   - crypt + gen_salt('bf')            : parola hash (bcrypt)
-- =====================================================================

-- Şifreleme anahtarı (gerçekte ASLA kod içinde tutulmaz; ortam değişkeni /
-- anahtar kasası kullanılır. Demo için sabit anahtar kullanıyoruz.)
\set sifre_anahtari 'GizliBankaAnahtari#2025'

-- ---------------------------------------------------------------------
-- 1) Hassas veriyi ŞİFRELEYEREK ekle
-- ---------------------------------------------------------------------
TRUNCATE sifreli_kayitlar RESTART IDENTITY;

INSERT INTO sifreli_kayitlar (musteri_adi, tc_sifreli, kart_no_sifreli)
VALUES
  ('Ahmet Yilmaz',
   pgp_sym_encrypt('12345678901', :'sifre_anahtari'),
   pgp_sym_encrypt('4729111122223333', :'sifre_anahtari')),
  ('Ayse Demir',
   pgp_sym_encrypt('98765432109', :'sifre_anahtari'),
   pgp_sym_encrypt('5188444455556666', :'sifre_anahtari'));

-- ---------------------------------------------------------------------
-- 2) Diskte/sorguda veri OKUNAMAZ (şifreli bytea görünür)
-- ---------------------------------------------------------------------
\echo '### Sifreli hali - veriyi calan biri sunu gorur (anlamsiz): ###'
SELECT id, musteri_adi, left(encode(tc_sifreli,'hex'), 40) || '...' AS tc_diskte
FROM sifreli_kayitlar;

-- ---------------------------------------------------------------------
-- 3) Doğru anahtarla ÇÖZ (sadece anahtarı bilen okuyabilir)
-- ---------------------------------------------------------------------
\echo '### Dogru anahtarla cozulmus hali: ###'
SELECT id, musteri_adi,
       pgp_sym_decrypt(tc_sifreli, :'sifre_anahtari')      AS tc_kimlik,
       pgp_sym_decrypt(kart_no_sifreli, :'sifre_anahtari') AS kart_no
FROM sifreli_kayitlar;

-- ---------------------------------------------------------------------
-- 4) YANLIŞ anahtarla çözme denenirse HATA verir (güvenlik)
--    Aşağıdaki satır bilerek hata üretir - video için gösterin:
-- SELECT pgp_sym_decrypt(tc_sifreli, 'YanlisAnahtar') FROM sifreli_kayitlar;
--   --> ERROR: Wrong key or corrupt data
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 5) PAROLA DOĞRULAMA (hash karşılaştırma) - crypt() ile
--    Parola düz metin saklanmaz; girilen parola hash'lenip karşılaştırılır.
-- ---------------------------------------------------------------------
\echo '### Dogru parola ile giris denemesi (eslesirse satir doner): ###'
SELECT kullanici_adi, rol
FROM kullanicilar
WHERE kullanici_adi = 'ahmet'
  AND parola_hash = crypt('sifre123', parola_hash);   -- DOGRU parola

\echo '### Yanlis parola ile giris (bos doner = giris reddedildi): ###'
SELECT kullanici_adi, rol
FROM kullanicilar
WHERE kullanici_adi = 'ahmet'
  AND parola_hash = crypt('yanlis_parola', parola_hash);  -- YANLIS

\echo '### Sifreleme demosu tamamlandi ###'
