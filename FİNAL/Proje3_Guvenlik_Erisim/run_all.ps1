# =====================================================================
# PROJE 3 - Guvenlik ve Erisim Kontrolu - Otomatik Calistirma
# Kullanim:  .\run_all.ps1 -Sifre "POSTGRES_PAROLANIZ"
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Sifre,
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe",
    [string]$KullaniciAdi = "postgres"
)

# psql NOTICE mesajlari stderr'e gider; PowerShell durmasin diye Continue.
$ErrorActionPreference = "Continue"
$env:PGPASSWORD = $Sifre
$env:PGCLIENTENCODING = "UTF8"
$scriptDir = Join-Path $PSScriptRoot "scripts"
$logDosya  = Join-Path $PSScriptRoot ("calisma_logu_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

if (-not (Test-Path $PsqlPath)) {
    Write-Host "HATA: psql bulunamadi: $PsqlPath" -ForegroundColor Red
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

Calistir "01_create_database.sql" "postgres"
Calistir "02_schema.sql"          "guvenlik_db"
Calistir "03_veri.sql"            "guvenlik_db"
Calistir "04_erisim_yonetimi.sql" "guvenlik_db"
Calistir "05_sifreleme.sql"       "guvenlik_db"
Calistir "06_audit_log.sql"       "guvenlik_db"

# SQL Injection demosu (Python)
Write-Host "`n=== 07_sql_injection_demo.py ===" -ForegroundColor Cyan
Add-Content $logDosya "`n========== 07_sql_injection_demo.py =========="
python (Join-Path $scriptDir "07_sql_injection_demo.py") 2>&1 |
    Tee-Object -FilePath $logDosya -Append

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "TUM ADIMLAR TAMAMLANDI. Detaylar: $logDosya" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
$env:PGPASSWORD = $null
