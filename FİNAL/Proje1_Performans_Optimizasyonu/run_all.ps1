# =====================================================================
# PROJE 1 - Performans Optimizasyonu - Otomatik Kurulum ve Calistirma
# Kullanim:
#   .\run_all.ps1 -Sifre "POSTGRES_PAROLANIZ"
# Sadece veritabanini kurup veri uretmek icin:
#   .\run_all.ps1 -Sifre "..." -SadeceKurulum
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Sifre,
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe",
    [string]$KullaniciAdi = "postgres",
    [switch]$SadeceKurulum
)

# psql NOTICE/WARNING mesajlari stderr'e yazilir; bunlari PowerShell'in
# hata sanip durmamasi icin Continue kullaniyoruz. Gercek SQL hatalari
# psql'in -v ON_ERROR_STOP=1 ayari + $LASTEXITCODE kontrolu ile yakalanir.
$ErrorActionPreference = "Continue"
$env:PGPASSWORD = $Sifre
$env:PGCLIENTENCODING = "UTF8"
$scriptDir = Join-Path $PSScriptRoot "scripts"
$logDosya  = Join-Path $PSScriptRoot ("calisma_logu_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

if (-not (Test-Path $PsqlPath)) {
    Write-Host "HATA: psql bulunamadi: $PsqlPath" -ForegroundColor Red
    Write-Host "PostgreSQL kurulu mu? Yolu -PsqlPath ile verin." -ForegroundColor Yellow
    exit 1
}

function Calistir($dosya, $veritabani) {
    $yol = Join-Path $scriptDir $dosya
    Write-Host "`n=== $dosya  (db: $veritabani) ===" -ForegroundColor Cyan
    Add-Content $logDosya "`n========== $dosya (db: $veritabani) =========="
    & $PsqlPath -U $KullaniciAdi -d $veritabani -v ON_ERROR_STOP=1 -f $yol 2>&1 |
        Tee-Object -FilePath $logDosya -Append
    if ($LASTEXITCODE -ne 0) {
        Write-Host "HATA: $dosya basarisiz (cikis kodu $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "PostgreSQL: $PsqlPath" -ForegroundColor Green
Write-Host "Log dosyasi: $logDosya" -ForegroundColor Green

# 1) Veritabanini olustur (postgres db'ye baglanarak)
Calistir "01_create_database.sql" "postgres"
# 2) Sema + buyuk veri (banka_db)
Calistir "02_schema.sql"       "banka_db"
Calistir "03_veri_uretimi.sql" "banka_db"

if ($SadeceKurulum) {
    Write-Host "`nKurulum tamam. Analiz scriptlerini atladiniz (-SadeceKurulum)." -ForegroundColor Green
    exit 0
}

# 3) Performans analizi ve optimizasyon
Calistir "04_izleme.sql"            "banka_db"
Calistir "05_indeks_yonetimi.sql"   "banka_db"
Calistir "06_sorgu_iyilestirme.sql" "banka_db"
Calistir "07_roller_erisim.sql"     "banka_db"
Calistir "08_disk_bakim.sql"        "banka_db"

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "TUM ADIMLAR TAMAMLANDI. Detaylar: $logDosya" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
$env:PGPASSWORD = $null
