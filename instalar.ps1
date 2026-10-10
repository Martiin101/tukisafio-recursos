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
  @{ n = 'TukiCielo-1.20.1.jar'; u = 'https://github.com/Martiin101/tukisafio-recursos/releases/download/cliente-2026-10-08/TukiCielo-1.20.1.jar'; s = 'c235ae6760c1a33f6bc916570869fce78ceffdcc' }
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
  [ServersDat]::Agregar((Join-Path $mc 'servers.dat'), 'Tukisafio', 'irvine-penalty.tun.ply.gg', 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAADU0lEQVR4nO2bW0gUYRTHz5ydXXXddNXKzUTJLqgYZBcxCEwy6jmRDKMghG5vYkQJSYjZglgQBVn0EKV5CSoKelARiUTJHjRDK8M03PWWirblmm6v/edhlmEJH8783n57vu+bMzucme+bC5GJiYlklFAHuJjtCvzrrjgHxANBNhgIYAtF0bTQ6MSPn+BVbz0h7QOTcJiEwyQc1WiH63nJULR5RXkQ35qzV7e/PW6Tbnx+fBBcUfAYfWrvAo+wtUA+V9pHDZ0TmITDJBwm4ahGOwx558F3eifBfy1gPCYxDZwd+8F9Yw3gLyrv6c4L1m6IBR+eWKBQYBIOk3CYhKMEa1CekwjX2a9erLnsjARwZyyuBbQUuCt049MjH8D7X3eCR62LBr/lbgZPca0Bv9rxXXcfmYTDJBwm4ajaH6oO4Fy/pOkuxE/sKQA/09gHnt9XDv50+1VwT48bXGELuCuzFPwczYA3a8ZbutYIXvb8Abgtvxj2p6xtBM4JTMJhEg6TcFTtD/YIK/j8xJDu3Hxx6hV4Q9I+8LrTeH8gOWMLblAzXuudbByvGucNi1MvdfOZHRsAd9htpAeTcJiEwyQcJViDkt3r4To6Nvsb4o8H8Tqtxa+p2abLlboJFLhxHmGNOUx6DxqKUp3gruhw8Js9k+ZaQA8m4TAJRw3WoObdBNTQyVQnVOF47w1oHx2P9/1tkVijKZnbdLdnsWIN+6dxnjHr+YLjqxZDNa+FSThMwmESjmq0Q2QYdnEm4Ny+u+4JeLg9DDyr6Di4omANv298BL689Ad819Fj4BHW0I4hk3CYhMMkHCXUAU6l47wg3hmpu15XGD2wEtDNSBufnPOB3++fMd8RCgUm4TAJRzXaoSI3Cd8RKsyF+O2aZ+DFZ3E9HxFpB/cMDIM7ovAc8rD+Dfj5C0fAN9e3Qj6XWr6ZawEjMAmHSTiq0Q5zPj/47IgH3GbB/9TuwJr+3PUR3GLBkt2YngJu1Yw3PTQKPrOA+RiFSThMwmESjmq0Q3WXF4o2oHnh36Kp2bRDB8F35BeCd9TWgvt9+NxBVXG8tpZezKd73FwLhAKTcJiEo/zvDZRm4TdFyysrEGfN/QJtzbs7Q/smKBhMwmESDq92AiYmJia0ivwF2nHMssXGDuwAAAAASUVORK5CYII=')
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
