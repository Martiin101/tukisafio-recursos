# Instalador del launcher de Tukisafio (Windows+R -> pegar -> Enter):
#   powershell -ep bypass -c "irm https://raw.githubusercontent.com/Martiin101/tukisafio-recursos/main/instalar.ps1 | iex"
# Baja el launcher que dice el manifiesto (verificado por sha1) a %APPDATA%\.tukisafio, le hace accesos directos en el
# escritorio y en el menu Inicio, y lo abre. Despues el launcher se actualiza solo. No toca .minecraft ni el TLauncher.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = 'Instalador de Tukisafio'
function Linea($texto, $color = 'Gray') { Write-Host $texto -ForegroundColor $color }

Linea '============================================================' DarkYellow
Linea '                  TUKISAFIO  -  INSTALADOR' Yellow
Linea '============================================================' DarkYellow
Linea ''
Linea 'Instala el launcher de Tukisafio (con acceso directo en el escritorio).'
Linea 'Lo demas (Java, Minecraft, Forge y los mods) lo baja el launcher solo.'
Linea ''
try {
  $manifiesto = Invoke-RestMethod 'https://raw.githubusercontent.com/Martiin101/tukisafio-recursos/main/launcher/manifiesto.json'
  $carpeta = Join-Path $env:APPDATA '.tukisafio'
  New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
  $exe = Join-Path $carpeta 'Tukisafio.exe'
  Get-Process Tukisafio -ErrorAction SilentlyContinue | Stop-Process -Force
  Linea 'Bajando el launcher...'
  Invoke-WebRequest -Uri $manifiesto.launcher_url -OutFile "$exe.nuevo" -UseBasicParsing
  $h = (Get-FileHash -Algorithm SHA1 -Path "$exe.nuevo").Hash.ToLower()
  if ($h -ne $manifiesto.launcher_sha1) { Remove-Item "$exe.nuevo" -Force; throw "El launcher bajo mal (sha1 $h). Proba de nuevo." }
  Move-Item -Force "$exe.nuevo" $exe

  $sh = New-Object -ComObject WScript.Shell
  foreach ($dir in @([Environment]::GetFolderPath('Desktop'), (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'))) {
    $acceso = $sh.CreateShortcut((Join-Path $dir 'Tukisafio.lnk'))
    $acceso.TargetPath = $exe
    $acceso.WorkingDirectory = $carpeta
    $acceso.IconLocation = "$exe,0"
    $acceso.Description = 'Launcher de Tukisafio'
    $acceso.Save()
  }
  Linea ''
  Linea '============================================================' Green
  Linea '  LISTO. Ya tenes "Tukisafio" en el escritorio.' Green
  Linea '  Se abre solo: pone tu nombre y apreta JUGAR.' Green
  Linea '  La primera vez baja todo (unos minutos, depende de tu internet).' Green
  Linea '============================================================' Green
  Start-Process -FilePath $exe -WorkingDirectory $carpeta
  Start-Sleep -Seconds 4
} catch {
  Linea ''
  Linea ('Algo salio mal: ' + $_.Exception.Message) Red
  Linea 'Sacale una captura a esta ventana y mandasela a Martin.'
  Read-Host 'Apreta ENTER para cerrar' | Out-Null
}
