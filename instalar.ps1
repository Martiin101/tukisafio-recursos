# Instalador de Tukisafio (por comando). Lo arma paquete-jugadores/instalador/armar-ps1.py; no editar a mano.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = 'Instalador de Tukisafio'

function Linea($texto, $color = 'Gray') { Write-Host $texto -ForegroundColor $color }

Linea '============================================================' DarkYellow
Linea '                  TUKISAFIO  -  INSTALADOR' Yellow
Linea '============================================================' DarkYellow
Linea ''
Linea 'Instala Forge 1.20.1, los mods del server y agrega Tukisafio'
Linea 'a tu lista de Multijugador.'
Linea ''
Linea 'Cerra Minecraft y el TLauncher antes de seguir.' Red
Read-Host 'Apreta ENTER para instalar' | Out-Null

$FORGE = '1.20.1-forge-47.3.22'
$mc = Join-Path $env:APPDATA '.minecraft'
$tmp = Join-Path $env:TEMP 'tukisafio-instalador'
New-Item -ItemType Directory -Force -Path $mc, $tmp | Out-Null

function Bajar($url, $destino, $sha1) {
  Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing
  $h = (Get-FileHash -Algorithm SHA1 -Path $destino).Hash.ToLower()
  if ($h -ne $sha1) { Remove-Item $destino -Force; throw "El archivo $(Split-Path $destino -Leaf) bajo mal (sha1 $h). Proba de nuevo." }
}

try {
  # ---------- 1. Forge ----------
  if (Test-Path (Join-Path $mc "versions\$FORGE\$FORGE.json")) {
    Linea '[1/3] Forge 1.20.1 ya estaba instalado.'
  } else {
    Linea '[1/3] Instalando Forge 1.20.1 (1 o 2 minutos)...'
    $java = $null
    $cand = @()
    $tl = Join-Path $env:APPDATA '.tlauncher\starter\jre_default'
    if (Test-Path $tl) { $cand += Get-ChildItem $tl -Directory -Filter 'jre-*' | ForEach-Object { Join-Path $_.FullName 'bin\java.exe' } }
    foreach ($r in 'java-runtime-gamma', 'java-runtime-delta', 'java-runtime-beta') {
      $cand += Join-Path $mc "runtime\$r\windows\$r\bin\java.exe"
      $cand += Join-Path $mc "runtime\$r\windows-x64\$r\bin\java.exe"
    }
    $enPath = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($enPath) { $cand += $enPath.Source }
    foreach ($c in $cand) { if (-not $java -and (Test-Path $c)) { $java = $c } }
    if (-not $java) { throw 'No encontre Java. Abri el TLauncher una vez, cerralo y volve a probar.' }
    $perfiles = Join-Path $mc 'launcher_profiles.json'
    if (-not (Test-Path $perfiles)) { Set-Content -Path $perfiles -Value '{"profiles":{}}' -Encoding ASCII }
    $jar = Join-Path $tmp 'forge-installer.jar'
    Bajar 'https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.22/forge-1.20.1-47.3.22-installer.jar' $jar 'a4620a69b9075fb543ae3efaff3690c76cd45844'
    $log = Join-Path $env:TEMP 'tukisafio-forge.log'
    $p = Start-Process -FilePath $java -ArgumentList @('-jar', "`"$jar`"", '--installClient', "`"$mc`"") -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    if (-not (Test-Path (Join-Path $mc "versions\$FORGE\$FORGE.json"))) { throw "No se pudo instalar Forge. Mandale a Martin el archivo $log" }
    Linea '      Listo.' Green
  }

  # ---------- 2. Mods ----------
  Linea '[2/3] Bajando los mods...'
  $mods = @(
  @{ n = 'geckolib-forge-1.20.1-4.8.4.jar'; u = 'https://cdn.modrinth.com/data/8BmcQJ2H/versions/aC5KMoNg/geckolib-forge-1.20.1-4.8.4.jar'; s = '50e1407869ef0e909e3bdda9328b8bd7db03fdc0' }
  @{ n = 'CustomPlayerModels-1.20-0.6.27a.jar'; u = 'https://cdn.modrinth.com/data/h1E7sQNL/versions/BZZSHBbA/CustomPlayerModels-1.20-0.6.27a.jar'; s = '4652dee093c796799756f5f6c89314c6d601ae65' }
  @{ n = 'Pehkui-3.8.2+1.20.1-forge.jar'; u = 'https://cdn.modrinth.com/data/t5W7Jfwy/versions/SQpqSgAE/Pehkui-3.8.2%2B1.20.1-forge.jar'; s = '4bc816efdd8e5e2a97423313674401351710e403' }
  @{ n = 'dedsafio3-fan.jar'; u = 'https://github.com/Martiin101/tukisafio-recursos/releases/download/cliente-2026-10-08/dedsafio3-fan.jar'; s = '3fbfb935949c1938eaf6ac7e9f3dbfa4f5083d12' }
  @{ n = 'TukiCielo-1.20.1.jar'; u = 'https://github.com/Martiin101/tukisafio-recursos/releases/download/cliente-2026-10-08/TukiCielo-1.20.1.jar'; s = '2c696373613f40e6365db890dac6d98bf4f45ecd' }
  )
  $carpeta = Join-Path $mc 'mods'
  New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
  $nuestros = $mods | ForEach-Object { $_.n }
  $ajenos = @(Get-ChildItem $carpeta -Filter '*.jar' | Where-Object { $nuestros -notcontains $_.Name })
  if ($ajenos.Count -gt 0) {
    $viejos = Join-Path $mc 'mods-antes-de-tukisafio'
    if (Test-Path $viejos) { $viejos += '-' + (Get-Date -Format 'yyyyMMdd-HHmmss') }
    New-Item -ItemType Directory -Force -Path $viejos | Out-Null
    $ajenos | Move-Item -Destination $viejos
    Linea "      Tenias otros mods: los guarde en $viejos (no se borraron)."
  }
  foreach ($m in $mods) {
    $destino = Join-Path $carpeta $m.n
    if ((Test-Path $destino) -and ((Get-FileHash -Algorithm SHA1 $destino).Hash.ToLower() -eq $m.s)) { continue }
    Linea "      $($m.n)"
    Bajar $m.u $destino $m.s
  }
  Linea '      Listo.' Green

  # ---------- 3. Server en la lista ----------
  Linea '[3/3] Agregando Tukisafio a tu lista de servers...'
  Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
// NBT minimo (big-endian, sin comprimir, como servers.dat). Los numeros se guardan como bytes crudos.
public class Nbt
{
    public byte Tipo;
    public string Nombre = "";
    public object Valor;          // string (8), byte[] crudo (1-7, 11, 12)
    public List<Nbt> Hijos = new List<Nbt>(); // compuesto (10) o lista (9)
    public byte TipoElementos;    // lista

    public static Nbt Compuesto(string nombre) { Nbt n = new Nbt(); n.Tipo = 10; n.Nombre = nombre; return n; }
    public static Nbt Lista(string nombre, byte tipo) { Nbt n = new Nbt(); n.Tipo = 9; n.Nombre = nombre; n.TipoElementos = tipo; return n; }
    public static Nbt Texto(string nombre, string v) { Nbt n = new Nbt(); n.Tipo = 8; n.Nombre = nombre; n.Valor = v; return n; }
    public static Nbt Byte(string nombre, byte v) { Nbt n = new Nbt(); n.Tipo = 1; n.Nombre = nombre; n.Valor = new byte[] { v }; return n; }

    public Nbt Buscar(string nombre)
    {
        foreach (Nbt h in Hijos) if (h.Nombre == nombre) return h;
        return null;
    }

    public void Poner(Nbt nuevo)
    {
        for (int i = 0; i < Hijos.Count; i++)
        {
            if (Hijos[i].Nombre == nuevo.Nombre) { Hijos[i] = nuevo; return; }
        }
        Hijos.Add(nuevo);
    }

    static byte[] Leer(BinaryReader r, int n) { byte[] b = r.ReadBytes(n); if (b.Length != n) throw new EndOfStreamException(); return b; }
    static int Entero(BinaryReader r) { byte[] b = Leer(r, 4); return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]; }
    static int Corto(BinaryReader r) { byte[] b = Leer(r, 2); return (b[0] << 8) | b[1]; }
    static string Cadena(BinaryReader r) { return Encoding.UTF8.GetString(Leer(r, Corto(r))); }

    public static Nbt LeerConNombre(BinaryReader r)
    {
        Nbt n = new Nbt();
        n.Tipo = r.ReadByte();
        if (n.Tipo == 0) return n;
        n.Nombre = Cadena(r);
        n.LeerCarga(r);
        return n;
    }

    void LeerCarga(BinaryReader r)
    {
        switch (Tipo)
        {
            case 1: Valor = Leer(r, 1); break;
            case 2: Valor = Leer(r, 2); break;
            case 3: case 5: Valor = Leer(r, 4); break;
            case 4: case 6: Valor = Leer(r, 8); break;
            case 7: { int len = Entero(r); Valor = Concat(Largo(len), Leer(r, len)); break; }
            case 11: { int len = Entero(r); Valor = Concat(Largo(len), Leer(r, len * 4)); break; }
            case 12: { int len = Entero(r); Valor = Concat(Largo(len), Leer(r, len * 8)); break; }
            case 8: Valor = Cadena(r); break;
            case 9:
                {
                    TipoElementos = r.ReadByte();
                    int len = Entero(r);
                    for (int i = 0; i < len; i++)
                    {
                        Nbt h = new Nbt();
                        h.Tipo = TipoElementos;
                        h.LeerCarga(r);
                        Hijos.Add(h);
                    }
                    break;
                }
            case 10:
                while (true)
                {
                    Nbt h = LeerConNombre(r);
                    if (h.Tipo == 0) break;
                    Hijos.Add(h);
                }
                break;
            default: throw new InvalidDataException("NBT desconocido " + Tipo);
        }
    }

    static byte[] Largo(int n) { return new byte[] { (byte)(n >> 24), (byte)(n >> 16), (byte)(n >> 8), (byte)n }; }
    static byte[] Concat(byte[] a, byte[] b) { byte[] c = new byte[a.Length + b.Length]; a.CopyTo(c, 0); b.CopyTo(c, a.Length); return c; }

    static void EscribirCadena(BinaryWriter w, string s)
    {
        byte[] b = Encoding.UTF8.GetBytes(s);
        w.Write((byte)(b.Length >> 8)); w.Write((byte)b.Length); w.Write(b);
    }

    public void EscribirConNombre(BinaryWriter w)
    {
        w.Write(Tipo);
        EscribirCadena(w, Nombre);
        EscribirCarga(w);
    }

    void EscribirCarga(BinaryWriter w)
    {
        switch (Tipo)
        {
            case 8: EscribirCadena(w, (string)Valor); break;
            case 9:
                w.Write(Hijos.Count == 0 ? (byte)0 : TipoElementos);
                w.Write(Largo(Hijos.Count));
                foreach (Nbt h in Hijos) h.EscribirCarga(w);
                break;
            case 10:
                foreach (Nbt h in Hijos) h.EscribirConNombre(w);
                w.Write((byte)0);
                break;
            default: w.Write((byte[])Valor); break;
        }
    }
}

public static class ServersDat
{
    public static void Agregar(string archivo, string nombre, string ip, string icono)
    {
        Nbt raiz = null;
        if (File.Exists(archivo))
        {
            try
            {
                using (BinaryReader r = new BinaryReader(File.OpenRead(archivo))) { raiz = Nbt.LeerConNombre(r); }
                File.Copy(archivo, archivo + ".antes-de-tukisafio", true);
            }
            catch (Exception) { raiz = null; }
        }
        if (raiz == null || raiz.Tipo != 10) raiz = Nbt.Compuesto("");
        Nbt lista = raiz.Buscar("servers");
        if (lista == null || lista.Tipo != 9)
        {
            lista = Nbt.Lista("servers", 10);
            raiz.Hijos.RemoveAll(delegate(Nbt n) { return n.Nombre == "servers"; });
            raiz.Hijos.Add(lista);
        }
        lista.TipoElementos = 10;
        Nbt server = null;
        foreach (Nbt s in lista.Hijos)
        {
            Nbt i = s.Buscar("ip"); Nbt n = s.Buscar("name");
            if ((i != null && (string)i.Valor == ip) || (n != null && (string)n.Valor == nombre)) { server = s; break; }
        }
        if (server == null) { server = Nbt.Compuesto(""); lista.Hijos.Insert(0, server); }
        server.Poner(Nbt.Texto("name", nombre));
        server.Poner(Nbt.Texto("ip", ip));
        server.Poner(Nbt.Texto("icon", icono));
        server.Poner(Nbt.Byte("acceptTextures", 1));
        using (BinaryWriter w = new BinaryWriter(File.Create(archivo))) { raiz.EscribirConNombre(w); }
    }
}

'@
  [ServersDat]::Agregar((Join-Path $mc 'servers.dat'), 'Tukisafio', 'irvine-penalty.tun.ply.gg', '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')
  Linea '      Listo.' Green

  Linea ''
  Linea '============================================================' Green
  Linea '  TODO LISTO. Ahora:' Green
  Linea '  1. Abri el TLauncher.'
  Linea "  2. Abajo, en la lista de versiones, elegi:  $FORGE"
  Linea '  3. Multijugador > Tukisafio (ya esta en tu lista).'
  Linea '============================================================' Green
} catch {
  Linea ''
  Linea ('Algo salio mal: ' + $_.Exception.Message) Red
  Linea 'Sacale una captura a esta ventana y mandasela a Martin.'
}
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Read-Host 'Apreta ENTER para cerrar' | Out-Null
