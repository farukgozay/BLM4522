# =====================================================================
# PROJE 7 - zamanlanmis_gorev_kur.ps1
# Windows Gorev Zamanlayici'da her gun calisan bir yedekleme gorevi
# olusturur. Bu, SQL Server Agent'in birebir karsiligidir.
#
# Kullanim:
#   .\zamanlanmis_gorev_kur.ps1 -Sifre "Banka2025"            # gunluk 02:00
#   .\zamanlanmis_gorev_kur.ps1 -Sifre "Banka2025" -Saat "23:30"
#   .\zamanlanmis_gorev_kur.ps1 -Kaldir                        # gorevi sil
#
# NOT: Gorev olusturmak icin PowerShell'i "Yonetici olarak calistir".
# =====================================================================
param(
    [string]$Sifre,
    [string]$Saat = "02:00",
    [string]$GorevAdi = "BankaYedekGorevi",
    [switch]$Kaldir
)

if ($Kaldir) {
    Unregister-ScheduledTask -TaskName $GorevAdi -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Gorev kaldirildi: $GorevAdi" -ForegroundColor Yellow
    return
}

if (-not $Sifre) { Write-Host "HATA: -Sifre gerekli." -ForegroundColor Red; exit 1 }

$yedekScript = Join-Path $PSScriptRoot "yedekle.ps1"

# Gorevin calistiracagi komut: powershell -File yedekle.ps1 -Sifre ...
$eylem = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$yedekScript`" -Sifre `"$Sifre`""

# Her gun belirtilen saatte
$tetik = New-ScheduledTaskTrigger -Daily -At $Saat

$ayar = New-ScheduledTaskSettingsSet -StartWhenAvailable

Register-ScheduledTask -TaskName $GorevAdi -Action $eylem -Trigger $tetik `
    -Settings $ayar -Description "Banka veritabani gunluk otomatik yedek (BLM4522 Proje 7)" `
    -Force | Out-Null

Write-Host "Zamanlanmis gorev olusturuldu: '$GorevAdi' her gun saat $Saat" -ForegroundColor Green
Write-Host "Kontrol: Get-ScheduledTask -TaskName $GorevAdi" -ForegroundColor Cyan
Write-Host "Hemen test: Start-ScheduledTask -TaskName $GorevAdi" -ForegroundColor Cyan

# Olusan gorevin ozetini goster
Get-ScheduledTask -TaskName $GorevAdi |
    Select-Object TaskName, State |
    Format-Table -AutoSize
