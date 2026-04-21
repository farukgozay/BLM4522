-- =====================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 2: Örnek Veri Ekleme
-- =====================================================

-- Kategoriler
INSERT INTO kategoriler (kategori_adi, aciklama) VALUES
('Elektronik', 'Elektronik cihazlar ve aksesuarlar'),
('Giyim', 'Kadın, erkek ve çocuk giyim ürünleri'),
('Ev & Yaşam', 'Ev dekorasyon ve yaşam ürünleri'),
('Spor', 'Spor ekipmanları ve giyim'),
('Kitap', 'Kitaplar ve kırtasiye ürünleri');

INSERT INTO kategoriler (kategori_adi, aciklama, ust_kategori_id) VALUES
('Telefon', 'Cep telefonları ve aksesuarları', 1),
('Bilgisayar', 'Dizüstü ve masaüstü bilgisayarlar', 1),
('Erkek Giyim', 'Erkek kıyafetleri', 2),
('Kadın Giyim', 'Kadın kıyafetleri', 2),
('Mutfak', 'Mutfak gereçleri ve küçük ev aletleri', 3);

-- Müşteriler (50 kayıt)
INSERT INTO musteriler (ad, soyad, email, telefon, adres, sehir) VALUES
('Ahmet', 'Yılmaz', 'ahmet.yilmaz@email.com', '05301234567', 'Atatürk Cad. No:12', 'İstanbul'),
('Fatma', 'Kaya', 'fatma.kaya@email.com', '05321234568', 'Cumhuriyet Mah. No:5', 'Ankara'),
('Mehmet', 'Demir', 'mehmet.demir@email.com', '05331234569', 'İnönü Sok. No:8', 'İzmir'),
('Ayşe', 'Çelik', 'ayse.celik@email.com', '05341234570', 'Barbaros Blv. No:22', 'İstanbul'),
('Mustafa', 'Şahin', 'mustafa.sahin@email.com', '05351234571', 'Mevlana Cad. No:15', 'Konya'),
('Zeynep', 'Yıldız', 'zeynep.yildiz@email.com', '05361234572', 'Gazi Cad. No:3', 'Bursa'),
('Ali', 'Özdemir', 'ali.ozdemir@email.com', '05371234573', 'Fevzi Paşa Cad. No:9', 'Antalya'),
('Elif', 'Arslan', 'elif.arslan@email.com', '05381234574', 'Kültür Mah. No:17', 'Eskişehir'),
('Hasan', 'Doğan', 'hasan.dogan@email.com', '05391234575', 'Zafer Sok. No:6', 'Kayseri'),
('Merve', 'Aydın', 'merve.aydin@email.com', '05401234576', 'Bahçe Sok. No:11', 'Trabzon'),
('Emre', 'Koç', 'emre.koc@email.com', '05411234577', 'Şehit Cad. No:4', 'Samsun'),
('Büşra', 'Kurt', 'busra.kurt@email.com', '05421234578', 'Çiçek Sok. No:20', 'Gaziantep'),
('Oğuz', 'Polat', 'oguz.polat@email.com', '05431234579', 'Lale Sok. No:13', 'Adana'),
('Selin', 'Öztürk', 'selin.ozturk@email.com', '05441234580', 'Gül Cad. No:7', 'Mersin'),
('Berk', 'Kılıç', 'berk.kilic@email.com', '05451234581', 'Park Cad. No:25', 'Diyarbakır'),
('Deniz', 'Yalçın', 'deniz.yalcin@email.com', '05461234582', 'Pınar Sok. No:2', 'Erzurum'),
('Cem', 'Erdoğan', 'cem.erdogan@email.com', '05471234583', 'Meşe Sok. No:18', 'Malatya'),
('İrem', 'Güneş', 'irem.gunes@email.com', '05481234584', 'Çınar Cad. No:30', 'Hatay'),
('Kaan', 'Aktaş', 'kaan.aktas@email.com', '05491234585', 'Selvi Sok. No:14', 'Manisa'),
('Pınar', 'Çetin', 'pinar.cetin@email.com', '05501234586', 'Akasya Cad. No:10', 'Balıkesir'),
('Tolga', 'Korkmaz', 'tolga.korkmaz@email.com', '05511234587', 'Orkide Sok. No:8', 'Tekirdağ'),
('Gizem', 'Aksoy', 'gizem.aksoy@email.com', '05521234588', 'Papatya Cad. No:16', 'Aydın'),
('Serkan', 'Taş', 'serkan.tas@email.com', '05531234589', 'Menekşe Sok. No:21', 'Denizli'),
('Neslihan', 'Özkan', 'neslihan.ozkan@email.com', '05541234590', 'Karanfil Cad. No:5', 'Muğla'),
('Burak', 'Aslan', 'burak.aslan@email.com', '05551234591', 'Sümbül Sok. No:12', 'Elazığ'),
('Cansu', 'Yılmazer', 'cansu.yilmazer@email.com', '05561234592', 'Lale Cad. No:28', 'Van'),
('Furkan', 'Tunç', 'furkan.tunc@email.com', '05571234593', 'Nilüfer Sok. No:9', 'Rize'),
('Damla', 'Acar', 'damla.acar@email.com', '05581234594', 'Zambak Cad. No:33', 'Bolu'),
('Onur', 'Başaran', 'onur.basaran@email.com', '05591234595', 'Nergis Sok. No:7', 'Kastamonu'),
('Tuğba', 'Ateş', 'tugba.ates@email.com', '05601234596', 'Yasemin Cad. No:19', 'Çanakkale'),
('Murat', 'Şen', 'murat.sen@email.com', '05611234597', 'Begonvil Sok. No:24', 'Afyon'),
('Ezgi', 'Duman', 'ezgi.duman@email.com', '05621234598', 'Mimoza Cad. No:11', 'Uşak'),
('Barış', 'Çakır', 'baris.cakir@email.com', '05631234599', 'Fulya Sok. No:6', 'Kütahya'),
('Sibel', 'Kara', 'sibel.kara@email.com', '05641234600', 'Manolya Cad. No:15', 'Zonguldak'),
('Ufuk', 'Güler', 'ufuk.guler@email.com', '05651234601', 'Çiğdem Sok. No:22', 'Edirne'),
('Aslı', 'Keskin', 'asli.keskin@email.com', '05661234602', 'Lavanta Cad. No:8', 'Tokat'),
('Volkan', 'Erdem', 'volkan.erdem@email.com', '05671234603', 'Biberiye Sok. No:31', 'Sakarya'),
('Melis', 'Karagöz', 'melis.karagoz@email.com', '05681234604', 'Defne Cad. No:13', 'Düzce'),
('Caner', 'Sezer', 'caner.sezer@email.com', '05691234605', 'Kekik Sok. No:26', 'Yalova'),
('Hande', 'Bilgin', 'hande.bilgin@email.com', '05701234606', 'Nane Cad. No:4', 'Kırklareli'),
('Ercan', 'Yavuz', 'ercan.yavuz@email.com', '05711234607', 'Adaçayı Sok. No:17', 'Çorum'),
('Gamze', 'Orhan', 'gamze.orhan@email.com', '05721234608', 'Biberiye Cad. No:29', 'Amasya'),
('Tamer', 'Bulut', 'tamer.bulut@email.com', '05731234609', 'Kişniş Sok. No:10', 'Sinop'),
('Esra', 'Tekin', 'esra.tekin@email.com', '05741234610', 'Safran Cad. No:23', 'Bartın'),
('Uğur', 'Sarı', 'ugur.sari@email.com', '05751234611', 'Tarçın Sok. No:35', 'Karabük'),
('Dilara', 'Bayrak', 'dilara.bayrak@email.com', '05761234612', 'Sumak Cad. No:18', 'Kırıkkale'),
('Kemal', 'Uysal', 'kemal.uysal@email.com', '05771234613', 'Kimyon Sok. No:12', 'Aksaray'),
('Burcu', 'Özer', 'burcu.ozer@email.com', '05781234614', 'Zerdeçal Cad. No:27', 'Niğde'),
('Serhat', 'Tan', 'serhat.tan@email.com', '05791234615', 'Karabiber Sok. No:5', 'Karaman'),
('Yasemin', 'Çevik', 'yasemin.cevik@email.com', '05801234616', 'Zencefil Cad. No:20', 'Iğdır');

-- Ürünler (30 kayıt)
INSERT INTO urunler (urun_adi, kategori_id, fiyat, stok_miktari, aciklama) VALUES
('iPhone 15 Pro', 6, 64999.99, 25, '256GB, Titanium Doğal'),
('Samsung Galaxy S24', 6, 44999.00, 40, '256GB, Phantom Black'),
('Xiaomi 14', 6, 24999.00, 60, '512GB, Siyah'),
('MacBook Air M3', 7, 52999.00, 15, '8GB RAM, 256GB SSD'),
('Lenovo ThinkPad', 7, 35999.00, 20, 'i7, 16GB RAM, 512GB SSD'),
('HP Pavilion', 7, 28999.00, 30, 'Ryzen 7, 16GB RAM'),
('Erkek Slim Fit Gömlek', 8, 599.90, 200, 'Pamuklu, Beyaz'),
('Erkek Chino Pantolon', 8, 799.90, 150, 'Slim Fit, Lacivert'),
('Erkek Deri Ceket', 8, 3499.90, 45, 'Gerçek Deri, Siyah'),
('Kadın Trençkot', 9, 2999.90, 55, 'Bej, Uzun Model'),
('Kadın Elbise', 9, 1299.90, 80, 'Çiçek Desenli, Midi Boy'),
('Kadın Spor Ayakkabı', 9, 1899.90, 100, 'Beyaz, Deri'),
('Airfryer', 10, 4999.00, 35, '5.5L, Dijital Gösterge'),
('Robot Süpürge', 10, 8999.00, 20, 'Lazer Navigasyon, Mop'),
('Kahve Makinesi', 10, 6499.00, 25, 'Tam Otomatik Espresso'),
('Koşu Bandı', 4, 12999.00, 10, 'Katlanabilir, 18 km/h'),
('Dambıl Seti', 4, 2499.00, 50, '2x10kg, Neopren Kaplı'),
('Yoga Matı', 4, 399.00, 200, 'TPE, 6mm, Mor'),
('Spor Çanta', 4, 899.00, 75, 'Su Geçirmez, 40L'),
('Koşu Ayakkabısı', 4, 2999.00, 60, 'Nike Air Max, Siyah'),
('Türk Edebiyatı Seti', 5, 599.00, 100, '10 Kitap Set'),
('Python Programlama', 5, 189.00, 150, 'Başlangıçtan İleri Seviye'),
('Veri Yapıları', 5, 159.00, 120, 'Algoritma ve Veri Yapıları'),
('SQL Öğreniyorum', 5, 129.00, 80, 'Temel ve İleri SQL'),
('Yapay Zeka', 5, 249.00, 90, 'Derin Öğrenme ile AI'),
('Bluetooth Kulaklık', 6, 1999.00, 70, 'ANC, 30 Saat Pil'),
('Tablet', 6, 15999.00, 25, 'iPad Air, 64GB'),
('Akıllı Saat', 6, 8999.00, 40, 'Apple Watch Series 9'),
('Monitör', 7, 7999.00, 30, '27 inç, 4K, IPS'),
('Mekanik Klavye', 7, 2499.00, 55, 'RGB, Cherry MX Red');

-- Siparişler (100 kayıt) ve detayları
DO $$
DECLARE
    i INT;
    v_musteri_id INT;
    v_siparis_id INT;
    v_urun_id INT;
    v_miktar INT;
    v_fiyat DECIMAL(10,2);
    v_toplam DECIMAL(12,2);
    v_durum VARCHAR(20);
    v_tarih TIMESTAMP;
    durumlar VARCHAR(20)[] := ARRAY['beklemede', 'hazirlaniyor', 'kargoda', 'teslim_edildi', 'iptal'];
BEGIN
    FOR i IN 1..100 LOOP
        v_musteri_id := (random() * 49 + 1)::INT;
        v_durum := durumlar[(random() * 4 + 1)::INT];
        v_tarih := CURRENT_TIMESTAMP - (random() * 180 || ' days')::INTERVAL;

        INSERT INTO siparisler (musteri_id, siparis_tarihi, toplam_tutar, durum, kargo_adresi)
        VALUES (v_musteri_id, v_tarih, 0, v_durum,
                'Kargo Adresi - Sipariş ' || i)
        RETURNING siparis_id INTO v_siparis_id;

        v_toplam := 0;
        FOR j IN 1..(random() * 3 + 1)::INT LOOP
            v_urun_id := (random() * 29 + 1)::INT;
            v_miktar := (random() * 3 + 1)::INT;
            SELECT fiyat INTO v_fiyat FROM urunler WHERE urun_id = v_urun_id;

            INSERT INTO siparis_detaylari (siparis_id, urun_id, miktar, birim_fiyat)
            VALUES (v_siparis_id, v_urun_id, v_miktar, v_fiyat);

            v_toplam := v_toplam + (v_miktar * v_fiyat);
        END LOOP;

        UPDATE siparisler SET toplam_tutar = v_toplam WHERE siparis_id = v_siparis_id;

        IF v_durum IN ('kargoda', 'teslim_edildi') THEN
            INSERT INTO odemeler (siparis_id, odeme_tarihi, tutar, odeme_yontemi, durum)
            VALUES (v_siparis_id, v_tarih + INTERVAL '1 hour', v_toplam,
                    (ARRAY['kredi_karti', 'havale', 'kapida_odeme'])[(random() * 2 + 1)::INT],
                    'onaylandi');
        END IF;
    END LOOP;
END $$;

-- Veri kontrolü
SELECT 'musteriler' AS tablo, COUNT(*) AS kayit_sayisi FROM musteriler
UNION ALL SELECT 'kategoriler', COUNT(*) FROM kategoriler
UNION ALL SELECT 'urunler', COUNT(*) FROM urunler
UNION ALL SELECT 'siparisler', COUNT(*) FROM siparisler
UNION ALL SELECT 'siparis_detaylari', COUNT(*) FROM siparis_detaylari
UNION ALL SELECT 'odemeler', COUNT(*) FROM odemeler;
