@echo off
REM =====================================================
REM PROJE 2: Tam Yedekleme (Full Backup) Scripti
REM PostgreSQL pg_dump ile tam yedek alma
REM =====================================================

SET PGPASSWORD=postgres
SET PGUSER=postgres
SET PGHOST=localhost
SET PGPORT=5432
SET DB_NAME=eticaret_db

SET BACKUP_DIR=C:\pg_backups\full
SET TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%
SET BACKUP_FILE=%BACKUP_DIR%\full_backup_%TIMESTAMP%.dump

IF NOT EXIST "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo ===================================================
echo    TAM YEDEKLEME BASLATILIYOR
echo    Veritabani: %DB_NAME%
echo    Dosya: %BACKUP_FILE%
echo    Tarih: %DATE% %TIME%
echo ===================================================

REM Yedekleme logunu veritabanina kaydet
psql -d %DB_NAME% -c "INSERT INTO yedekleme_log (yedek_tipi, dosya_adi, baslangic_zamani, durum) VALUES ('TAM', '%BACKUP_FILE%', CURRENT_TIMESTAMP, 'baslatildi');"

REM pg_dump ile tam yedek al (custom format = sıkıştırılmış)
pg_dump -Fc -v -f "%BACKUP_FILE%" %DB_NAME%

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo [BASARILI] Tam yedekleme tamamlandi!
    echo Dosya: %BACKUP_FILE%

    REM Dosya boyutunu al
    FOR %%A IN ("%BACKUP_FILE%") DO SET FILE_SIZE=%%~zA
    SET /A FILE_SIZE_MB=%FILE_SIZE% / 1048576

    REM Logu güncelle
    psql -d %DB_NAME% -c "UPDATE yedekleme_log SET bitis_zamani = CURRENT_TIMESTAMP, durum = 'basarili', boyut_mb = %FILE_SIZE_MB% WHERE dosya_adi = '%BACKUP_FILE%';"
) ELSE (
    echo.
    echo [HATA] Yedekleme basarisiz oldu!
    psql -d %DB_NAME% -c "UPDATE yedekleme_log SET bitis_zamani = CURRENT_TIMESTAMP, durum = 'basarisiz', hata_mesaji = 'pg_dump hatasi' WHERE dosya_adi = '%BACKUP_FILE%';"
)

echo.
echo === Son 5 Yedekleme Logu ===
psql -d %DB_NAME% -c "SELECT log_id, yedek_tipi, durum, baslangic_zamani, boyut_mb FROM yedekleme_log ORDER BY log_id DESC LIMIT 5;"

echo.

REM Sadece SQL formatında da bir yedek al (okunabilir metin)
SET SQL_BACKUP=%BACKUP_DIR%\full_backup_%TIMESTAMP%.sql
pg_dump --format=plain --verbose --file="%SQL_BACKUP%" %DB_NAME%

IF %ERRORLEVEL% EQU 0 (
    echo [BASARILI] SQL formati yedek de olusturuldu: %SQL_BACKUP%
) ELSE (
    echo [HATA] SQL formati yedek olusturulamadi.
)

pause
