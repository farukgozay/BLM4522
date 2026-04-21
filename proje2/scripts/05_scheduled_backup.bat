@echo off
REM =====================================================
REM PROJE 2: Zamanlayıcı ile Otomatik Yedekleme
REM Windows Task Scheduler kullanarak periyodik yedekleme
REM =====================================================

SET PGPASSWORD=postgres
SET PGUSER=postgres
SET PGHOST=localhost
SET PGPORT=5432
SET DB_NAME=eticaret_db
SET BACKUP_DIR=C:\pg_backups\scheduled

IF NOT EXIST "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo ===================================================
echo    ZAMANLANMIS YEDEKLEME SISTEMI
echo ===================================================
echo.

REM -- Seçenek 1: Günlük tam yedekleme görevi oluşturma
echo [1/4] Gunluk tam yedekleme gorevi olusturuluyor...
echo.
echo Asagidaki komutu yonetici olarak calistirin:
echo.
echo   schtasks /create /tn "PostgreSQL_Gunluk_Yedekleme" ^
echo     /tr "%~dp003_full_backup.bat" ^
echo     /sc daily /st 02:00 ^
echo     /ru SYSTEM
echo.

REM -- Seçenek 2: Saatlik fark yedekleme
echo [2/4] Saatlik fark yedekleme gorevi...
echo.

SET TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%
SET TIMESTAMP=%TIMESTAMP: =0%
SET DIFF_FILE=%BACKUP_DIR%\diff_backup_%TIMESTAMP%.dump

echo Fark yedegi aliniyor...
pg_dump -Fc -v -f "%DIFF_FILE%" %DB_NAME%

IF %ERRORLEVEL% EQU 0 (
    echo [BASARILI] Fark yedegi: %DIFF_FILE%
    psql -d %DB_NAME% -c "INSERT INTO yedekleme_log (yedek_tipi, dosya_adi, baslangic_zamani, bitis_zamani, durum) VALUES ('ZAMANLANMIS', '%DIFF_FILE%', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'basarili');"
)

REM -- Seçenek 3: Eski yedekleri temizleme (7 günden eski)
echo.
echo [3/4] 7 gunden eski yedekler temizleniyor...
forfiles /P "%BACKUP_DIR%" /S /M *.dump /D -7 /C "cmd /c del @path" 2>nul
IF %ERRORLEVEL% EQU 0 (
    echo Eski yedekler silindi.
) ELSE (
    echo Silinecek eski yedek bulunamadi.
)

REM -- Mevcut zamanlanmış görevleri listele
echo.
echo [4/4] PostgreSQL ile ilgili zamanlanmis gorevler:
schtasks /query /FO TABLE | findstr /i "PostgreSQL" 2>nul
IF %ERRORLEVEL% NEQ 0 (
    echo Henuz zamanlanmis gorev bulunamadi.
    echo Yukaridaki schtasks komutunu yonetici olarak calistirin.
)

echo.
echo === Scheduled Backup Klasoru ===
dir "%BACKUP_DIR%" /B 2>nul

echo.
echo ===================================================
echo Windows Task Scheduler ile zamanlama ornek komutlari:
echo.
echo Gunluk (her gece 02:00):
echo   schtasks /create /tn "PG_Daily" /tr "%~dp003_full_backup.bat" /sc daily /st 02:00
echo.
echo Saatlik:
echo   schtasks /create /tn "PG_Hourly" /tr "%~dp005_scheduled_backup.bat" /sc hourly
echo.
echo Haftalik (Pazar 03:00):
echo   schtasks /create /tn "PG_Weekly" /tr "%~dp003_full_backup.bat" /sc weekly /d SUN /st 03:00
echo ===================================================

pause
