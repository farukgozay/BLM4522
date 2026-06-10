# =====================================================================
# PROJE 7 - Yedekleme ve Otomasyon - Uctan uca demo
# Sirasiyla: veritabani kur -> basarili yedek -> basarisiz yedek (uyari)
#           -> rapor -> geri yukleme testi
# Kullanim:  .\run_all.ps1 -Sifre "Banka2025"
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Sifre,
    [string]$BinDir = "C:\Program Files\PostgreSQL\18\bin",
    [string]$KullaniciAdi = "postgres"
)

$ErrorActionPreference = "Continue"
$env:PGCLIENTENCODING = "UTF8"
$psql = Join-Path $BinDir "psql.exe"
$scriptDir = Join-Path $PSScriptRoot "scripts"
$logDosya = Join-Path $PSScriptRoot ("calisma_logu_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

Write-Host "PostgreSQL bin: $BinDir" -ForegroundColor Green
Write-Host "Log: $logDosya`n" -ForegroundColor Green

# 1) Veritabani + veri
$env:PGPASSWORD = $Sifre
Write-Host "=== 1) Veritabani olusturuluyor ===" -ForegroundColor Cyan
& $psql -U $KullaniciAdi -d postgres      -v ON_ERROR_STOP=1 -f (Join-Path $scriptDir "01_create_database.sql") 2>&1 | Tee-Object -FilePath $logDosya -Append
& $psql -U $KullaniciAdi -d yedekleme_db  -v ON_ERROR_STOP=1 -f (Join-Path $scriptDir "02_veri.sql")            2>&1 | Tee-Object -FilePath $logDosya -Append
$env:PGPASSWORD = $null

# 2) Basarili yedek
Write-Host "`n=== 2) Basarili yedek aliniyor ===" -ForegroundColor Cyan
& (Join-Path $scriptDir "yedekle.ps1") -Sifre $Sifre 2>&1 | Tee-Object -FilePath $logDosya -Append

# 3) Basarisiz yedek (uyari mekanizmasini test et)
Write-Host "`n=== 3) Basarisiz yedek simulasyonu (uyari testi) ===" -ForegroundColor Cyan
& (Join-Path $scriptDir "yedekle.ps1") -Sifre $Sifre -HataSimulasyonu 2>&1 | Tee-Object -FilePath $logDosya -Append

# 4) Ikinci basarili yedek (rapor zenginlessin)
& (Join-Path $scriptDir "yedekle.ps1") -Sifre $Sifre 2>&1 | Tee-Object -FilePath $logDosya -Append

# 5) Rapor
Write-Host "`n=== 4) Yedekleme raporu ===" -ForegroundColor Cyan
& (Join-Path $scriptDir "yedek_raporu.ps1") -Sifre $Sifre 2>&1 | Tee-Object -FilePath $logDosya -Append

# 6) Geri yukleme testi
Write-Host "`n=== 5) Geri yukleme (felaketten kurtarma) testi ===" -ForegroundColor Cyan
& (Join-Path $scriptDir "geri_yukle_test.ps1") -Sifre $Sifre 2>&1 | Tee-Object -FilePath $logDosya -Append

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "TAMAMLANDI. Zamanlanmis gorev icin (Yonetici PowerShell):" -ForegroundColor Green
Write-Host "  .\scripts\zamanlanmis_gorev_kur.ps1 -Sifre `"$Sifre`"" -ForegroundColor Yellow
Write-Host "Detayli log: $logDosya" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
