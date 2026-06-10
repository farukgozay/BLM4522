# =====================================================================
# PROJE 7 - yedekle.ps1
# Veritabanini pg_dump ile yedekler, sonucu yedekleme_log tablosuna ve
# bir log dosyasina yazar. Basarisiz olursa UYARI uretir.
# (SQL Server Agent + PowerShell Scripting + Otomatik Uyari karsiligi)
#
# Kullanim:
#   .\yedekle.ps1 -Sifre "Banka2025"
#   .\yedekle.ps1 -Sifre "Banka2025" -HataSimulasyonu   # uyari mekanizmasini test et
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Sifre,
    [string]$Veritabani = "yedekleme_db",
    [string]$BinDir = "C:\Program Files\PostgreSQL\18\bin",
    [string]$KullaniciAdi = "postgres",
    [switch]$HataSimulasyonu
)

$ErrorActionPreference = "Continue"
$env:PGPASSWORD = $Sifre
$env:PGCLIENTENCODING = "UTF8"

$psql    = Join-Path $BinDir "psql.exe"
$pgdump  = Join-Path $BinDir "pg_dump.exe"
$kokDizin = Split-Path $PSScriptRoot -Parent
$yedekDir = Join-Path $kokDizin "yedekler"
$uyariLog = Join-Path $kokDizin "uyari_log.txt"
if (-not (Test-Path $yedekDir)) { New-Item -ItemType Directory -Path $yedekDir | Out-Null }

$zaman    = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$yedekDosya = Join-Path $yedekDir "yedek_${Veritabani}_$zaman.backup"
# Tabloya yazarken Turkce karakterli tam yol yerine SADECE dosya adini (ASCII)
# kullaniyoruz; aksi halde psql -c argumaninda UTF8 kodlama hatasi olusur.
$dosyaAdi = Split-Path $yedekDosya -Leaf

function LogSql($sql) {
    & $psql -U $KullaniciAdi -d $Veritabani -q -t -A -v ON_ERROR_STOP=1 -c $sql
}

Write-Host "=== Yedekleme basliyor: $Veritabani -> $yedekDosya ===" -ForegroundColor Cyan

# 1) yedekleme_log'a 'basladi' kaydi ekle ve log_id al
# psql ciktisindan ilk tam sayiyi (RETURNING log_id) regex ile guvenli al;
# "INSERT 0 1" gibi komut etiketleri karismasin diye.
$insertCikti = LogSql "INSERT INTO yedekleme_log(yedek_tipi, dosya_adi, durum) VALUES ('tam', '$dosyaAdi', 'basladi') RETURNING log_id;"
$logId = ([regex]::Match([string]$insertCikti, '\d+')).Value

try {
    # 2) Asil yedek (pg_dump custom format -Fc: sikistirilmis, pg_restore ile geri yuklenebilir)
    if ($HataSimulasyonu) {
        throw "Simule edilmis yedekleme hatasi (disk dolu / baglanti koptu)."
    }
    & $pgdump -U $KullaniciAdi -d $Veritabani -Fc -f $yedekDosya
    if ($LASTEXITCODE -ne 0) { throw "pg_dump cikis kodu $LASTEXITCODE" }
    if (-not (Test-Path $yedekDosya)) { throw "Yedek dosyasi olusmadi." }

    # 3) Basari: boyut hesapla, log'u guncelle
    $boyutMb = [math]::Round((Get-Item $yedekDosya).Length / 1MB, 2)
    LogSql "UPDATE yedekleme_log SET durum='basarili', bitis=now(), boyut_mb=$boyutMb WHERE log_id=$logId;" | Out-Null
    Write-Host "BASARILI: $yedekDosya ($boyutMb MB)" -ForegroundColor Green
}
catch {
    # 4) HATA: log'u guncelle + UYARI uret
    $hata = $_.Exception.Message -replace "'", "''"
    LogSql "UPDATE yedekleme_log SET durum='basarisiz', bitis=now(), hata_mesaji='$hata' WHERE log_id=$logId;" | Out-Null

    $uyariMetni = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] YEDEKLEME BASARISIZ - $Veritabani - $($_.Exception.Message)"
    Add-Content -Path $uyariLog -Value $uyariMetni
    Write-Host "`n!!! UYARI: YEDEKLEME BASARISIZ !!!" -ForegroundColor Red
    Write-Host $uyariMetni -ForegroundColor Red
    Write-Host "Yoneticiye bildirim: $uyariLog dosyasina yazildi." -ForegroundColor Yellow

    # --- E-POSTA UYARISI (gercek SMTP varsa acin) ---
    # Send-MailMessage -To "dba@banka.com" -From "yedek@banka.com" `
    #   -Subject "Yedekleme Basarisiz: $Veritabani" -Body $uyariMetni `
    #   -SmtpServer "smtp.banka.com"
    exit 1
}
finally {
    $env:PGPASSWORD = $null
}
