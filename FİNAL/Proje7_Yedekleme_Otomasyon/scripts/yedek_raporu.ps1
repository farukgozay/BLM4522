# =====================================================================
# PROJE 7 - yedek_raporu.ps1
# Yedekleme gecmisini raporlar:
#   1) yedekleme_log tablosundan istatistikler (basarili/basarisiz)
#   2) yedekler/ klasorundeki fiziksel yedek dosyalari ve boyutlari
# (PDF: "PowerShell ... ile yedekleme raporlari olusturma")
#
# Kullanim:  .\yedek_raporu.ps1 -Sifre "Banka2025"
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Sifre,
    [string]$Veritabani = "yedekleme_db",
    [string]$BinDir = "C:\Program Files\PostgreSQL\18\bin",
    [string]$KullaniciAdi = "postgres"
)

$ErrorActionPreference = "Continue"
$env:PGPASSWORD = $Sifre
$env:PGCLIENTENCODING = "UTF8"
$psql = Join-Path $BinDir "psql.exe"

Write-Host "`n============== YEDEKLEME RAPORU ==============" -ForegroundColor Cyan
Write-Host "Tarih: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# 1) Ozet istatistik
Write-Host "--- Ozet (yedekleme_log) ---" -ForegroundColor Green
& $psql -U $KullaniciAdi -d $Veritabani -c @"
SELECT
    count(*)                                   AS toplam_yedek,
    count(*) FILTER (WHERE durum='basarili')   AS basarili,
    count(*) FILTER (WHERE durum='basarisiz')  AS basarisiz,
    round(coalesce(sum(boyut_mb),0),2)         AS toplam_mb,
    max(bitis)                                 AS son_yedek_zamani
FROM yedekleme_log;
"@

# 2) Son 10 yedek detayi
Write-Host "--- Son 10 yedek ---" -ForegroundColor Green
& $psql -U $KullaniciAdi -d $Veritabani -c @"
SELECT log_id, yedek_tipi AS tip,
       to_char(baslangic,'YYYY-MM-DD HH24:MI:SS') AS baslangic,
       round(extract(epoch FROM (bitis-baslangic))::numeric,2) AS sure_sn,
       boyut_mb, durum,
       coalesce(left(hata_mesaji,40),'') AS hata
FROM yedekleme_log ORDER BY log_id DESC LIMIT 10;
"@

# 3) Basarisiz yedek uyarisi
$basarisiz = (& $psql -U $KullaniciAdi -d $Veritabani -t -A -c "SELECT count(*) FROM yedekleme_log WHERE durum='basarisiz';").Trim()
if ([int]$basarisiz -gt 0) {
    Write-Host "`n!!! DIKKAT: $basarisiz adet BASARISIZ yedek var! uyari_log.txt kontrol edin. !!!" -ForegroundColor Red
} else {
    Write-Host "`nTum yedekler basarili. Sorun yok." -ForegroundColor Green
}

# 4) Fiziksel yedek dosyalari
$yedekDir = Join-Path (Split-Path $PSScriptRoot -Parent) "yedekler"
Write-Host "`n--- Fiziksel yedek dosyalari ($yedekDir) ---" -ForegroundColor Green
if (Test-Path $yedekDir) {
    Get-ChildItem $yedekDir -Filter *.backup | Sort-Object LastWriteTime -Descending |
        Select-Object Name,
            @{N='Boyut_MB';E={[math]::Round($_.Length/1MB,2)}},
            @{N='Tarih';E={$_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')}} |
        Format-Table -AutoSize
} else {
    Write-Host "Henuz yedek dosyasi yok." -ForegroundColor Yellow
}

$env:PGPASSWORD = $null
Write-Host "============== RAPOR SONU ==============`n" -ForegroundColor Cyan
