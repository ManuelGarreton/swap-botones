<#
  Oculta el control REAL con HidHide (el virtual de ViGEmBus no se toca)
  y permite que el python indicado lo siga viendo.
  Uso: ocultar_control.ps1 -Python C:\ruta\python.exe [-VidPid 'VID_045E&PID_028E']
#>
param(
  [Parameter(Mandatory = $true)][string]$Python,
  [string]$VidPid = 'VID_045E&PID_028E'
)
$ErrorActionPreference = 'Continue'
$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'diagnostico.txt'
Start-Transcript -Path $log -Force | Out-Null

$cli = 'C:\Program Files\Nefarius Software Solutions\HidHide\x64\HidHideCLI.exe'
if (-not (Test-Path $cli)) { Write-Host 'ERROR: no encuentro HidHideCLI.exe (instala HidHide).'; Stop-Transcript | Out-Null; exit 1 }

# Permitir a python (y pythonw) ver el control real
$pyw = Join-Path (Split-Path $Python) 'pythonw.exe'
foreach ($exe in @($Python, $pyw)) { if (Test-Path $exe) { & $cli --app-reg $exe; Write-Host "Permitido: $exe" } }

# Cerrar swap_botones si esta corriendo, para no ocultar el control virtual
Get-Process python, pythonw -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $Python -or $_.Path -eq $pyw } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1

$devs = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match [regex]::Escape($VidPid) }
$n = 0
foreach ($d in $devs) {
  $parent = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_Parent' -ErrorAction SilentlyContinue).Data
  $virtual = ($parent -match '^ROOT\\') -or ($parent -match 'VIGEM') -or ($d.InstanceId -match 'VIGEM')
  Write-Host ("- {0} | clase={1} | {2} | padre={3} | virtual={4}" -f $d.FriendlyName, $d.Class, $d.InstanceId, $parent, $virtual)
  if (-not $virtual) { & $cli --dev-hide $d.InstanceId; $n++ }
}
& $cli --cloak-on

Write-Host ''
Write-Host '--- Apps permitidas:'; & $cli --app-list
Write-Host '--- Dispositivos ocultos:'; & $cli --dev-list
Write-Host ''
if ($n -gt 0) { Write-Host "OK: $n dispositivo(s) ocultado(s). Desenchufa y vuelve a enchufar el control." }
else { Write-Host "AVISO: no encontre dispositivos $VidPid. Esta el control enchufado?" }
Stop-Transcript | Out-Null
