# =====================================================================
# PROJE 7 - geri_yukle_test.ps1
# Bir yedegin GERCEKTEN calistigini dogrular (felaketten kurtarma testi):
#   1) En son yedek dosyasini bul
#   2) Gecici bir veritabanina (yedek_test_db) geri yukle (pg_restore)
#   3) Satir sayilarini kontrol et
#   4) Gecici veritabanini sil
# (PDF: "yedeklerin duzenli olarak alindigini dogrulamak icin denetim")
#
# Kullanim:  .\geri_yukle_test.ps1 -Sifre "Banka2025"
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Sifre,
    [string]$BinDir = "C:\Program Files\PostgreSQL\18\bin",
    [string]$KullaniciAdi = "postgres",
    [string]$TestDb = "yedek_test_db"
)

$ErrorActionPreference = "Continue"
$env:PGPASSWORD = $Sifre
$env:PGCLIENTENCODING = "UTF8"
$psql     = Join-Path $BinDir "psql.exe"
$pgrestore = Join-Path $BinDir "pg_restore.exe"
$yedekDir = Join-Path (Split-Path $PSScriptRoot -Parent) "yedekler"

# 1) En son yedek dosyasi
$sonYedek = Get-ChildItem $yedekDir -Filter *.backup -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $sonYedek) {
    Write-Host "HATA: Geri yuklenecek yedek dosyasi bulunamadi. Once yedekle.ps1 calistirin." -ForegroundColor Red
    exit 1
}
Write-Host "Test edilecek yedek: $($sonYedek.Name)" -ForegroundColor Cyan

# 2) Gecici test veritabani olustur
& $psql -U $KullaniciAdi -d postgres -c "DROP DATABASE IF EXISTS $TestDb;" | Out-Null
& $psql -U $KullaniciAdi -d postgres -c "CREATE DATABASE $TestDb;" | Out-Null

# 3) Geri yukle
Write-Host "Geri yukleniyor -> $TestDb ..." -ForegroundColor Cyan
& $pgrestore -U $KullaniciAdi -d $TestDb $sonYedek.FullName
if ($LASTEXITCODE -ne 0) {
    Write-Host "UYARI: pg_restore bazi uyarilar verdi (cikis kodu $LASTEXITCODE)." -ForegroundColor Yellow
}

# 4) Dogrulama: satir sayilari
Write-Host "`n--- Geri yuklenen veritabani dogrulamasi ---" -ForegroundColor Green
$musteri = (& $psql -U $KullaniciAdi -d $TestDb -t -A -c "SELECT count(*) FROM musteriler;").Trim()
$islem   = (& $psql -U $KullaniciAdi -d $TestDb -t -A -c "SELECT count(*) FROM islemler;").Trim()
Write-Host ("musteriler satir sayisi : {0}" -f $musteri)
Write-Host ("islemler   satir sayisi : {0}" -f $islem)

if ([int]$musteri -gt 0 -and [int]$islem -gt 0) {
    Write-Host "`nSONUC: YEDEK GECERLI - geri yukleme basarili, veri eksiksiz." -ForegroundColor Green
} else {
    Write-Host "`nSONUC: YEDEK SORUNLU - geri yuklenen veri bos!" -ForegroundColor Red
}

# 5) Temizlik: gecici veritabanini sil
& $psql -U $KullaniciAdi -d postgres -c "DROP DATABASE IF EXISTS $TestDb;" | Out-Null
Write-Host "Gecici test veritabani ($TestDb) silindi." -ForegroundColor Cyan
$env:PGPASSWORD = $null
