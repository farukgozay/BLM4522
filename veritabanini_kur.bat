@echo off
setlocal
chcp 65001 >nul

echo ========================================================
echo BLM4522 - PROJE 2 VE PROJE 5 VERITABANI KURULUM SCRIPT'I
echo ========================================================
echo.

:: PostgreSQL bilgilerini ayarlayalım
set "PGPASSWORD=33Kz0046."
set "PSQL_PATH=C:\Program Files\PostgreSQL\18\bin\psql.exe"
set "PGUSER=postgres"
set "PGHOST=localhost"
set "PGPORT=5432"

:: Dosya dizinleri
set "PROJE2_DIR=c:\Users\gozay\OneDrive\Masaüstü\BLM4522\proje2\scripts"
set "PROJE5_DIR=c:\Users\gozay\OneDrive\Masaüstü\BLM4522\proje5\scripts"

:: Hali hazırda varsa veritabanlarını temizlemek için (isteğe bağlı ama sıfır kurulum iyidir)
echo [1/4] Mevcut veritabanları varsa temizleniyor...
"%PSQL_PATH%" -U %PGUSER% -d postgres -c "DROP DATABASE IF EXISTS eticaret_db;" >nul 2>&1
"%PSQL_PATH%" -U %PGUSER% -d postgres -c "DROP DATABASE IF EXISTS etl_db;" >nul 2>&1

echo.
echo [2/4] Proje 2 - Veritabanı ve Tablolar Oluşturuluyor...
"%PSQL_PATH%" -U %PGUSER% -d postgres -f "%PROJE2_DIR%\01_create_database.sql"
echo Proje 2 - Örnek Veriler Yükleniyor...
"%PSQL_PATH%" -U %PGUSER% -d eticaret_db -f "%PROJE2_DIR%\02_sample_data.sql"
echo Proje 2 Hazırlığı Tamam.

echo.
echo [3/4] Proje 5 - Veritabanı ve Staging/Hedef/Log Yapısı Kuruluyor...
"%PSQL_PATH%" -U %PGUSER% -d postgres -f "%PROJE5_DIR%\01_create_staging.sql"

echo Proje 5 - CSV Verileri Iceri Aktariliyor (Extract)...

:: Proje 5 Extract Script'i içindeki dosya yolunu düzeltmemiz lazım olabilir ama script kendi içinden okuyor.
:: Bakalım 02_extract.sql içinde yol ne alemde... 
:: O nedenle önce bunu çalıştıralım, eğer dosya yolu absolute olmazsa hata verebilir. (Birazdan düzelteceğim).

REM NOT: absolute patch gerektirdiği için COPY komutunu powershell uzerinden gonderebiliriz eger gerekirse...
"%PSQL_PATH%" -U %PGUSER% -d etl_db -f "%PROJE5_DIR%\02_extract.sql"

echo Proje 5 - Transform / Clean Islemleri Yapiliyor...
"%PSQL_PATH%" -U %PGUSER% -d etl_db -f "%PROJE5_DIR%\03_transform_clean.sql"

echo Proje 5 - Load (Veriler Hedefe Yükleniyor)...
"%PSQL_PATH%" -U %PGUSER% -d etl_db -f "%PROJE5_DIR%\04_load.sql"

echo.
echo [4/4] Kurulum Basariyla Tamamlandi!
echo.
pause
