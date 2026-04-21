@echo off
REM =====================================================
REM PROJE 2: WAL Arşivleme ve Point-in-Time Recovery
REM PostgreSQL WAL tabanlı artık yedekleme
REM =====================================================

SET PGPASSWORD=postgres
SET PGUSER=postgres
SET PGHOST=localhost
SET PGPORT=5432
SET DB_NAME=eticaret_db
SET PGDATA=C:\Program Files\PostgreSQL\16\data
SET WAL_ARCHIVE=C:\pg_backups\wal_archive
SET BASE_BACKUP_DIR=C:\pg_backups\base

IF NOT EXIST "%WAL_ARCHIVE%" mkdir "%WAL_ARCHIVE%"
IF NOT EXIST "%BASE_BACKUP_DIR%" mkdir "%BASE_BACKUP_DIR%"

echo ===================================================
echo    WAL ARSIVLEME YAPILANDIRMASI
echo ===================================================
echo.
echo [1/3] postgresql.conf ayarlarini kontrol ediliyor...
echo.
echo Asagidaki ayarlarin postgresql.conf dosyasinda yapilmis olmasi gerekir:
echo.
echo   wal_level = replica
echo   archive_mode = on
echo   archive_command = 'copy "%%p" "%WAL_ARCHIVE%\%%f"'
echo   max_wal_senders = 3
echo.
echo Bu ayarlari yapmak icin:
echo   1. "%PGDATA%\postgresql.conf" dosyasini acin
echo   2. Yukaridaki satirlari ekleyin/degistirin
echo   3. PostgreSQL servisini yeniden baslatin
echo.

REM WAL ayarlarını kontrol et
echo [2/3] Mevcut WAL ayarlarini kontrol ediliyor...
psql -d %DB_NAME% -c "SELECT name, setting FROM pg_settings WHERE name IN ('wal_level', 'archive_mode', 'archive_command', 'max_wal_senders');"

echo.
echo [3/3] Base backup aliniyor (pg_basebackup)...

SET TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%
SET TIMESTAMP=%TIMESTAMP: =0%
SET BASE_DIR=%BASE_BACKUP_DIR%\base_%TIMESTAMP%

pg_basebackup -D "%BASE_DIR%" -Ft -z -P -v

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo [BASARILI] Base backup alindi: %BASE_DIR%
    psql -d %DB_NAME% -c "INSERT INTO yedekleme_log (yedek_tipi, dosya_adi, baslangic_zamani, bitis_zamani, durum) VALUES ('BASE_BACKUP', '%BASE_DIR%', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'basarili');"
) ELSE (
    echo.
    echo [HATA] Base backup alinamadi!
    echo WAL ayarlarinin dogru yapilandirildigindan emin olun.
)

echo.
echo === WAL Arsiv Klasoru Icerigi ===
IF EXIST "%WAL_ARCHIVE%" (
    dir "%WAL_ARCHIVE%" /B 2>nul | find /c /v "" 
    echo dosya mevcut.
) ELSE (
    echo Arsiv klasoru henuz olusturulmamis.
)

pause
