# BLM4522 - Ağ Tabanlı Paralel Dağıtım Sistemleri Çalışmaları

Herkese merhaba! Ben Muhammed Faruk Gözay. Bu repository, Ankara Üniversitesi Bilgisayar Mühendisliği bölümünde aldığım **BLM4522** dersi kapsamında geliştirdiğim veritabanı projelerini içerir. Veritabanı yönetimi, veri güvenliği ve ETL alanında tamamen otonom çalışan süreçler inşa etmeye odaklandım. 

Repository içerisinde birbirini tamamlayan iki ana proje yer alıyor:

---

## 🛡️ Proje 2: Veritabanı Yedekleme ve Felaketten Kurtarma (Disaster Recovery) Planı 
Büyük ölçekli bir e-ticaret platformunda yaşanabilecek felaketlere karşı sıfır veri kaybı hedefiyle hazırladığım yedekleme ve kurtarma sistemidir. Verilerimiz `eticaret_db` veritabanında saklanmaktadır.

**Neler Yaptım?**
*   **7 Tablolu Dinamik Veritabanı:** PostgreSQL üzerinde siparişten ödemeye kadar tamamen birbirine (Foreign Key) bağlı ve sample datalarla beslenmiş gerçekçi bir yapı kurdum.
*   **Otonom Yedekleme Operasyonu:** `pg_dump` aracını ve Windows Görev Zamanlayıcısı'nı entegre ederek veritabanının günlük ve haftalık yedeklerini hiç insan müdahalesi olmadan otomatik olarak .dump ve .sql şeklinde alan `.bat` scriptleri hazırladım.
*   **Zaman Damgasına Dönüş & Rollback:** Transaction blockları kullanarak, bir memurun yanlışlıkla "DELETE" komutu atması durumunda dahi `SAVEPOINT` ile anında sistemi geri kurtarabilen (Rollback) felaket önleme senaryolarını canlı olarak test ettim. Her yedek ve hata da bir log tablosuna sicil olarak güvenle işleniyor.

---

## 🧹 Proje 5: Veri Temizleme ve Uçtan Uca ETL (Extract, Transform, Load) Stratejisi
Günümüzde veritabanlarını çöplüğe dönüştüren dış kaynaklı bozuk verilere (Dirty Data) karşı geliştirdiğim otomatik bir 3 katmanlı "Veri Barajı" tasarımıdır. PostgreSQL tabanlı `etl_db` veritabanında çalışmaktadır.

**Neler Yaptım?**
*   **Mimari Kurulum:** Ham verilerin alındığı `staging`, temizlenmiş ana verilerin tutulduğu `hedef` ve hatalı logların kaydolduğu `etl_log` adında spesifik bir 3 katmanlı mimari hazırladım.
*   **Veri Çıkarma (Extract):** `COPY` komutu kullanarak formatı, büyük/küçük harfi karışık, fiyatı eksi(-) olan veya duplike edilmiş binlerce bozuk csv datasını staging havuzuna attım.
*   **Dönüştürme ve Arıtma (Transform & Load):** Regex kullanarak format kontrolleri sağladım, SQL `ROW_NUMBER()` ile duplike kayıtları sildim. Kirli veriyi temizleyip referans bütünlük kısıtlamalarından başarıyla geçirerek hedefe saf veriyi (Pure Data) ulaştırdım. Tüm bu işlemler esnasında tespit edilen yüzlerce veri hatası teker teker raporlandı.

---

### 📂 Dosyalarımı Nasıl İncelersiniz?
*   `proje2/scripts` klasörü içinde yedekleme yapısını ayağa kaldıran tüm `.sql` ve otomatik çalışmayı sağlayan `.bat` scriptlerini bulabilirsiniz.
*   `proje5/scripts` klasöründe ise uçtan uca ETL veri temizliği sağlayan tüm kodlar parçalı olarak tutulmaktadır.
*   `generate_final_report.py` ile bu iki projeyi de devasa ve kusursuz bir Word & PDF belge raporuna dönüştüren raporlama script'ine ulaşabilirsiniz. `BLM4522_Proje2_ve_5_TEK_RAPOR_v3.docx` nihai dokümandır.

*Eğer buradaki çalışmaları incelediyseniz veya bu repository ile ilgilendiyseniz yıldız (star) vererek destek olabilirsiniz.*

> **Geliştirici:** Muhammed Faruk GÖZAY (22290673)
> **Ders:** BLM4522 - Öğr. Gör. Enver BAĞCI
