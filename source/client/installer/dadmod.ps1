# dadmod client installer / uninstaller (Windows PowerShell 5.1 or later).
#   Install dadmod.bat    -> dadmod.ps1 install   [-Game "<THUG Pro folder>"]
#   Uninstall dadmod.bat  -> dadmod.ps1 uninstall [-Game "<THUG Pro folder>"]
#   Repair dadmod.bat     -> dadmod.ps1 repair    [-Game "<THUG Pro folder>"]  (puts back any dadmod file or extra
#                            level that went missing, e.g. a map deleted from the custom maps folder)
#   the game (Pause > dadmod > Update dadmod) -> <game>\dadmod\updater\dadmod.ps1 update -Game "<game>" -WaitPid <pid>
#                            (a copy of this file the package installs; waits for the game to close, updates, restarts it)
# Works on a plain THUG Pro install or a Kali Mod install. It never changes a THUG Pro or Kali file:
#   - binkw32.dll is renamed binkw32_orig.dll (ours forwards every call to it) and put back on uninstall;
#   - everything else it adds is new: data\pre\dadmod_qb.prx, data\dadmod_casidle.qb, dadmod\menulevels\, and the extra
#     levels' files in data\pre and data\sounds (installer\vault_levels.txt; a copy the player already had is kept and left alone).
# What it did is written to <game>\dadmod\install.json; the uninstaller undoes exactly that. The unzipped
# dadmod-install folder stays (Noah 2026-11-17), so Setup.bat can install again from it.
# Setup.bat also updates: it checks the public releases repo ($UpdateRepo below) and installs a newer dadmod.zip.
# Your dadmod settings (dadmod\*.ini) stay after an uninstall.
param(
    [Parameter(Position = 0)][ValidateSet('menu', 'install', 'uninstall', 'repair', 'update')][string]$Action = 'menu',
    [string]$Game = '',
    [string]$PackageDir = '',
    [int]$WaitPid = 0,
    [string]$Zip = ''
)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
# Setup.bat unpacks files.dad to a temp folder and runs this from there; PackageDir is the folder the player
# unzipped (dadmod-install, with Setup.bat and files.dad). Without it, the package is the folder above installer\.
$Pkg = $PackageDir
if (-not $Pkg) { $Pkg = Split-Path -Parent $Here }
$Files = Join-Path (Split-Path -Parent $Here) 'files'
$Marker = 'dadmod client loader'

function Say($t) { Write-Host $t }
function Fail($t) { Write-Host ''; Write-Host "Stopped: $t" -ForegroundColor Red; exit 1 }

function Is-Game($p) { $p -and (Test-Path -LiteralPath (Join-Path $p 'THUGPro.exe')) -and (Test-Path -LiteralPath (Join-Path $p 'data\pre\thugpro_qb.prx')) }

function Is-Ours($dll) {
    if (-not (Test-Path -LiteralPath $dll)) { return $false }
    $b = [IO.File]::ReadAllBytes($dll)
    $s = [Text.Encoding]::ASCII.GetString($b)
    return $s.Contains($Marker)
}

function Md5($p) { (Get-FileHash -LiteralPath $p -Algorithm MD5).Hash.ToLower() }

function Find-Game {
    if ($Game) { if (Is-Game $Game) { return (Resolve-Path -LiteralPath $Game).Path }; Fail "no THUG Pro install at $Game" }
    # the package unzipped inside (or next to) the game folder
    $up = $Pkg
    foreach ($c in @($up, (Split-Path -Parent $up), (Split-Path -Parent (Split-Path -Parent $up)))) {
        if (Is-Game $c) { return $c }
    }
    # THUG Pro's own registry entry
    foreach ($k in @('HKCU:\Software\THUG Pro\Install', 'HKLM:\Software\THUG Pro\Install', 'HKLM:\Software\WOW6432Node\THUG Pro\Install')) {
        try {
            $props = Get-ItemProperty -Path $k -ErrorAction Stop
            foreach ($p in $props.PSObject.Properties) {
                if ($p.Value -is [string] -and (Is-Game $p.Value)) { return $p.Value }
            }
        } catch { }
    }
    foreach ($c in @("$env:LOCALAPPDATA\THUG Pro", "${env:ProgramFiles(x86)}\THUG Pro", "$env:ProgramFiles\THUG Pro", 'C:\THUG Pro')) {
        if (Is-Game $c) { return $c }
    }
    return Pick-Folder
}

function Pick-Folder {
    Add-Type -AssemblyName System.Windows.Forms
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = 'Pick your THUG Pro folder (the one with THUGPro.exe in it)'
    if ($d.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { Fail 'no folder picked' }
    if (-not (Is-Game $d.SelectedPath)) { Fail "no THUGPro.exe and data\pre\thugpro_qb.prx in $($d.SelectedPath)" }
    return $d.SelectedPath
}

# Kali Mod: it adds data\pre\thugpro_qe.prx (plain THUG Pro has none), and its scripts carry the "Kalimod" name
function Is-Kali($g) {
    if (Test-Path -LiteralPath (Join-Path $g 'data\pre\thugpro_qe.prx')) { return $true }
    try {
        $b = [IO.File]::ReadAllBytes((Join-Path $g 'data\pre\thugpro_qb.prx'))
        return [Text.Encoding]::ASCII.GetString($b).Contains('Kalimod')
    } catch { return $false }
}

# one numbered question; returns the number picked
function Ask($question, $choices) {
    while ($true) {
        Write-Host ''
        Write-Host $question
        for ($i = 0; $i -lt $choices.Count; $i++) { Write-Host ("  {0}) {1}" -f ($i + 1), $choices[$i]) }
        # one key press picks (no Enter; Noah 2026-11-17); Read-Host only if there's no real console
        Write-Host -NoNewline ('Press 1-' + $choices.Count + ': ')
        $a = $null
        try { $a = [string][Console]::ReadKey($true).KeyChar } catch { $a = Read-Host }
        Write-Host $a
        $n = 0
        if ([int]::TryParse("$a".Trim(), [ref]$n) -and $n -ge 1 -and $n -le $choices.Count) { return $n }
        Write-Host ('Press one of the numbers 1-' + $choices.Count + '.')
    }
}

# ---- updater (Noah 2026-11-17): new versions come from the public GitHub repo below (its releases, asset dadmod.zip;
# betas are pre-releases, which GitHub's "latest" skips, so the whole list is read and the highest version wins).
# No token, nothing uploaded. DADMOD_UPDATE_URL overrides the API address (local tests).
$UpdateRepo = 'nrpabst/Dadmod'

function Version-Of($t) {
    # "v0.9.8 beta" / "0.9.8" -> [version] 0.9.8 (anything after the numbers is ignored); $null when there are none
    $m = [regex]::Match("$t", '\d+(\.\d+){1,3}')
    if (-not $m.Success) { return $null }
    try { return [version]$m.Value } catch { return $null }
}

# -> @{ state = 'newer' | 'same' | 'none' | 'offline' | 'limit' | 'error'; version; tag; url; size; text }
function Check-Update($current) {
    $api = $env:DADMOD_UPDATE_URL
    if (-not $api) { $api = "https://api.github.com/repos/$UpdateRepo/releases?per_page=30" }
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
    $r = $null
    try {
        $req = [Net.HttpWebRequest]::Create($api)
        $req.UserAgent = 'dadmod-setup'
        $req.Accept = 'application/vnd.github+json'
        $req.Timeout = 8000
        $req.ReadWriteTimeout = 8000
        $resp = $req.GetResponse()
        $sr = New-Object IO.StreamReader($resp.GetResponseStream())
        $body = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
        $r = $body | ConvertFrom-Json
    } catch [Net.WebException] {
        $we = $_.Exception
        if ($we.Response) {
            $code = [int]$we.Response.StatusCode
            $left = $we.Response.Headers['X-RateLimit-Remaining']
            if ($code -eq 404) { return @{ state = 'none'; text = 'No dadmod releases are posted yet.' } }
            if (($code -eq 403 -or $code -eq 429) -and ($left -eq '0' -or $code -eq 429)) {
                return @{ state = 'limit'; text = 'GitHub says too many update checks from this connection right now. Try again in an hour.' }
            }
            return @{ state = 'error'; text = "The update check failed (GitHub answered $code). Try again later." }
        }
        return @{ state = 'offline'; text = 'Could not reach GitHub (no internet?). Skipping the update check.' }
    } catch {
        return @{ state = 'error'; text = 'The update check failed. Try again later.' }
    }
    # the highest version among the published releases (betas included) that carry a dadmod.zip
    $tag = $null; $v = $null; $asset = $null
    foreach ($rel in @($r)) {
        if (-not $rel -or $rel.draft) { continue }
        $rv = Version-Of "$($rel.tag_name)"
        if (-not $rv) { $rv = Version-Of "$($rel.name)" }
        $ra = $null
        foreach ($a in @($rel.assets)) { if ("$($a.name)" -ieq 'dadmod.zip') { $ra = $a } }
        if ($rv -and $ra -and (-not $v -or $rv -gt $v)) { $v = $rv; $tag = "$($rel.tag_name)"; $asset = $ra }
    }
    if (-not $v -or -not $asset) { return @{ state = 'none'; text = 'No dadmod release with a dadmod.zip is posted yet.' } }
    $cur = Version-Of $current
    if ($cur -and $v -le $cur) { return @{ state = 'same'; version = $v; tag = $tag; text = "You have the newest dadmod ($current)." } }
    return @{ state = 'newer'; version = $v; tag = $tag; url = "$($asset.browser_download_url)"; size = [long]$asset.size; text = "dadmod $tag is out (you have $current)." }
}

# downloads the release zip, puts its Setup.bat / files.dad / README.txt into this dadmod-install folder and runs the
# new version's installer on $g (the normal Update: settings in dadmod\ stay)
function Get-Update($u, $g, $have = '') {
    $tmp = Join-Path $env:TEMP ('dadmod_update_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp 'dadmod.zip'
        $mb = [math]::Round($u.size / 1MB)
        # the game already downloaded it (Pause > dadmod > Download newest update): use that copy when it's whole
        if ($have -and (Test-Path -LiteralPath $have) -and ($u.size -le 0 -or (Get-Item -LiteralPath $have).Length -eq $u.size)) {
            Say "Using the dadmod $($u.tag) download from the game ($mb MB)."
            $zip = $have
        } else {
            Say "Downloading dadmod $($u.tag) ($mb MB)..."
            try {
                $wc = New-Object Net.WebClient
                $wc.Headers.Add('User-Agent', 'dadmod-setup')
                $wc.DownloadFile($u.url, $zip)
            } catch { Say 'The download failed (internet dropped?). Nothing was changed. Try again later.'; return $false }
        }
        if ($u.size -gt 0 -and (Get-Item -LiteralPath $zip).Length -ne $u.size) { Say 'The download came out the wrong size. Nothing was changed. Try again later.'; return $false }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $x = Join-Path $tmp 'zip'
        try { [IO.Compression.ZipFile]::ExtractToDirectory($zip, $x) } catch { Say 'The downloaded zip is damaged. Nothing was changed. Try again later.'; return $false }
        $dad = @(Get-ChildItem -LiteralPath $x -Recurse -Filter 'files.dad')
        if ($dad.Count -ne 1) { Say 'The downloaded zip has no files.dad. Nothing was changed.'; return $false }
        $src = $dad[0].DirectoryName
        # unpack the new files.dad (same reader as Setup.bat: DADMODPK1 or the LZMA DADMODPK2) and run its installer
        if (-not ('DadmodPack2' -as [type])) {
            Add-Type -TypeDefinition @'
using System; using System.IO;
// dadmod files.dad reader (Noah 2026-11-18). DADMODPK1 = zip XORed with the key in header byte 15.
// DADMODPK2 = the same, but the zip (stored, no compression) is packed with LZMA ("alone" format: 5 property bytes,
// 8-byte size, LZMA data) before the XOR. Our own LZMA decoder, so nothing extra has to be installed on the PC.
public static class DadmodPack2 {
    sealed class Rd {
        Stream s; byte[] b = new byte[1 << 20]; int n, p; byte key;
        public Rd(Stream s, byte key) { this.s = s; this.key = key; }
        public int Byte() {
            if (p == n) { n = s.Read(b, 0, b.Length); p = 0; if (n <= 0) throw new Exception("files.dad is damaged (cut short)"); }
            return b[p++] ^ key;
        }
    }
    sealed class Lzma {
        Rd rd; uint range = 0xFFFFFFFF, code;
        byte[] win; int wsize, wpos; bool full; long total; Stream o;
        int lc, lp, pb;
        ushort[] isMatch = new ushort[192], isRep = new ushort[12], isRepG0 = new ushort[12], isRepG1 = new ushort[12],
            isRepG2 = new ushort[12], isRep0Long = new ushort[192], lit, posSlot = new ushort[4 * 64],
            posSpec = new ushort[115], align = new ushort[16];
        ushort[][] len = new ushort[2][];   // each: choice, choice2, low 16x8, mid 16x8, high 256
        public Lzma(Rd rd, Stream o, int props, uint dict) {
            this.rd = rd; this.o = o;
            if (props >= 9 * 5 * 5) throw new Exception("files.dad is damaged (bad header)");
            lc = props % 9; props /= 9; lp = props % 5; pb = props / 5;
            wsize = (int)Math.Max(dict, 4096u);
            win = new byte[wsize];
            lit = new ushort[0x300 << (lc + lp)];
            for (int i = 0; i < 2; i++) len[i] = new ushort[2 + 128 + 128 + 256];
            foreach (ushort[] a in new ushort[][] { isMatch, isRep, isRepG0, isRepG1, isRepG2, isRep0Long, lit, posSlot, posSpec, align, len[0], len[1] })
                for (int i = 0; i < a.Length; i++) a[i] = 1024;
            if (rd.Byte() != 0) throw new Exception("files.dad is damaged (bad stream)");
            for (int i = 0; i < 4; i++) code = (code << 8) | (uint)rd.Byte();
        }
        int Bit(ushort[] pr, int i) {
            uint v = pr[i], bound = (range >> 11) * v; int r;
            if (code < bound) { range = bound; pr[i] = (ushort)(v + ((2048 - v) >> 5)); r = 0; }
            else { range -= bound; code -= bound; pr[i] = (ushort)(v - (v >> 5)); r = 1; }
            if (range < (1u << 24)) { range <<= 8; code = (code << 8) | (uint)rd.Byte(); }
            return r;
        }
        uint Direct(int bits) {
            uint r = 0;
            while (bits-- > 0) {
                range >>= 1; code -= range;
                uint t = 0 - (code >> 31);
                code += range & t;
                r = (r << 1) + (t + 1);
                if (range < (1u << 24)) { range <<= 8; code = (code << 8) | (uint)rd.Byte(); }
            }
            return r;
        }
        int Tree(ushort[] pr, int off, int bits) {
            int m = 1;
            for (int i = 0; i < bits; i++) m = (m << 1) + Bit(pr, off + m);
            return m - (1 << bits);
        }
        int RevTree(ushort[] pr, int off, int bits) {
            int m = 1, s = 0;
            for (int i = 0; i < bits; i++) { int b = Bit(pr, off + m); m = (m << 1) + b; s |= b << i; }
            return s;
        }
        int Len(ushort[] pr, int ps) {
            if (Bit(pr, 0) == 0) return Tree(pr, 2 + ps * 8, 3);
            if (Bit(pr, 1) == 0) return 8 + Tree(pr, 2 + 128 + ps * 8, 3);
            return 16 + Tree(pr, 2 + 256, 8);
        }
        void Put(byte v) {
            win[wpos++] = v; total++;
            if (wpos == wsize) { o.Write(win, 0, wsize); wpos = 0; full = true; }
        }
        byte Back(uint d) {   // byte d+1 back
            int i = wpos - (int)d - 1; if (i < 0) i += wsize; return win[i];
        }
        public void Run(long size) {
            int state = 0; uint r0 = 0, r1 = 0, r2 = 0, r3 = 0;
            int pbm = (1 << pb) - 1, lpm = (1 << lp) - 1;
            while (size < 0 || total < size) {
                int ps = (int)total & pbm;
                if (Bit(isMatch, (state << 4) + ps) == 0) {
                    int prev = total > 0 ? Back(0) : 0;
                    int off = 0x300 * ((((int)total & lpm) << lc) + (prev >> (8 - lc)));
                    int sym = 1;
                    if (state >= 7) {
                        int mb = Back(r0);
                        while (sym < 0x100) {
                            int bm = (mb >> 7) & 1; mb <<= 1;
                            int b = Bit(lit, off + ((1 + bm) << 8) + sym);
                            sym = (sym << 1) | b;
                            if (bm != b) break;
                        }
                    }
                    while (sym < 0x100) sym = (sym << 1) | Bit(lit, off + sym);
                    Put((byte)sym);
                    state = state < 4 ? 0 : state < 10 ? state - 3 : state - 6;
                    continue;
                }
                int l;
                if (Bit(isRep, state) == 0) {
                    r3 = r2; r2 = r1; r1 = r0;
                    l = Len(len[0], ps);
                    state = state < 7 ? 7 : 10;
                    int slot = Tree(posSlot, (l < 3 ? l : 3) << 6, 6);
                    if (slot < 4) r0 = (uint)slot;
                    else {
                        int nb = (slot >> 1) - 1;
                        uint d = (uint)(2 | (slot & 1)) << nb;
                        if (slot < 14) d += (uint)RevTree(posSpec, (int)d - slot, nb);
                        else { d += Direct(nb - 4) << 4; d += (uint)RevTree(align, -1, 4); }
                        r0 = d;
                    }
                    if (r0 == 0xFFFFFFFF) {
                        if (size >= 0 && total != size) throw new Exception("files.dad is damaged (early end)");
                        break;
                    }
                } else {
                    if (total == 0) throw new Exception("files.dad is damaged (bad data)");
                    if (Bit(isRepG0, state) == 0) {
                        if (Bit(isRep0Long, (state << 4) + ps) == 0) {
                            state = state < 7 ? 9 : 11;
                            Put(Back(r0));
                            continue;
                        }
                    } else {
                        uint d;
                        if (Bit(isRepG1, state) == 0) d = r1;
                        else { if (Bit(isRepG2, state) == 0) d = r2; else { d = r3; r3 = r2; } r2 = r1; }
                        r1 = r0; r0 = d;
                    }
                    l = Len(len[1], ps);
                    state = state < 7 ? 8 : 11;
                }
                if (r0 >= (uint)wsize || (!full && r0 >= (uint)wpos)) throw new Exception("files.dad is damaged (bad distance)");
                l += 2;
                if (size >= 0 && total + l > size) throw new Exception("files.dad is damaged (too long)");
                int src = wpos - (int)r0 - 1; if (src < 0) src += wsize;
                while (l-- > 0) {
                    byte v = win[src]; if (++src == wsize) src = 0;
                    win[wpos++] = v; total++;
                    if (wpos == wsize) { o.Write(win, 0, wsize); wpos = 0; full = true; }
                }
            }
            o.Write(win, 0, wpos);
        }
    }
    // src = files.dad, dst = the zip it holds; reads DADMODPK1 and DADMODPK2
    public static void Unpack(string src, string dst) {
        using (FileStream i = new FileStream(src, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 16))
        using (FileStream o = new FileStream(dst, FileMode.Create, FileAccess.Write, FileShare.None, 1 << 20)) {
            byte[] h = new byte[16];
            if (i.Read(h, 0, 16) != 16) throw new Exception("files.dad is damaged");
            string magic = System.Text.Encoding.ASCII.GetString(h, 0, 9);
            byte key = h[15];
            if (magic == "DADMODPK1") {
                byte[] b = new byte[1 << 20];
                int n;
                while ((n = i.Read(b, 0, b.Length)) > 0) {
                    for (int k = 0; k < n; k++) b[k] ^= key;
                    o.Write(b, 0, n);
                }
                return;
            }
            if (magic != "DADMODPK2") throw new Exception("files.dad is damaged or from a newer dadmod");
            Rd rd = new Rd(i, key);
            int props = rd.Byte();
            uint dict = 0; for (int k = 0; k < 4; k++) dict |= (uint)rd.Byte() << (8 * k);
            ulong size = 0; for (int k = 0; k < 8; k++) size |= (ulong)rd.Byte() << (8 * k);
            if (dict > (1u << 30)) throw new Exception("files.dad is damaged (bad header)");
            new Lzma(rd, o, props, dict).Run(size == ulong.MaxValue ? -1 : (long)size);
        }
    }
}
'@
        }
        $inner = Join-Path $tmp 'pkg.zip'
        try { [DadmodPack2]::Unpack($dad[0].FullName, $inner) } catch { Say 'The downloaded files.dad is damaged. Nothing was changed.'; return $false }
        $nx = Join-Path $tmp 'x'
        [IO.Compression.ZipFile]::ExtractToDirectory($inner, $nx)
        Remove-Item -LiteralPath $inner -Force
        # keep this dadmod-install folder on the new version: files.dad and README.txt now; Setup.bat is still running,
        # so a hidden cmd swaps it in a moment after this window closes
        # (from the game's updater: only when the player's dadmod-install folder is known)
        $pkgOk = $Pkg -and (Test-Path -LiteralPath (Join-Path $Pkg 'Setup.bat'))
        if ($pkgOk) {
            foreach ($f in @('files.dad', 'README.txt')) {
                $s = Join-Path $src $f
                if (Test-Path -LiteralPath $s) { Copy-Item -LiteralPath $s -Destination (Join-Path $Pkg $f) -Force }
            }
            # INSTALL.txt was renamed README.txt (Noah 2026-11-18): move an old one out of the way so there aren't two
            $oldTxt = Join-Path $Pkg 'INSTALL.txt'
            if ((Test-Path -LiteralPath (Join-Path $Pkg 'README.txt')) -and (Test-Path -LiteralPath $oldTxt)) {
                $bak = Join-Path $g 'dadmod\backups'
                New-Item -ItemType Directory -Force -Path $bak | Out-Null
                Move-Item -LiteralPath $oldTxt -Destination (Join-Path $bak ('INSTALL.txt.old_' + (Get-Date).ToString('yyyyMMdd_HHmmss'))) -Force
            }
        }
        $newBat = Join-Path $src 'Setup.bat'
        if ($pkgOk -and (Test-Path -LiteralPath $newBat)) {
            $keep = Join-Path $env:TEMP ('dadmod_setup_new_' + [guid]::NewGuid().ToString('N') + '.bat')
            Copy-Item -LiteralPath $newBat -Destination $keep -Force
            $cmd = 'ping -n 4 127.0.0.1 >nul & copy /y "' + $keep + '" "' + (Join-Path $Pkg 'Setup.bat') + '" >nul & del /f /q "' + $keep + '"'
            Start-Process -FilePath $env:ComSpec -ArgumentList ('/c "' + $cmd + '"') -WindowStyle Hidden -WorkingDirectory $env:TEMP
        }
        Say ''
        Say "Installing dadmod $($u.tag)..."
        $ia = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $nx 'installer\dadmod.ps1'), 'install', '-Game', $g)
        if ($pkgOk) { $ia += @('-PackageDir', $Pkg) }
        & powershell @ia | Out-Host
        return ($LASTEXITCODE -eq 0)
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# the newest dadmod this player has: this package's version or what is installed in the game, whichever is newer
function Have-Version($g, $pkgVer) {
    $best = $pkgVer
    $iv = Join-Path $g 'dadmod\version.txt'
    if (Test-Path -LiteralPath $iv) {
        $t = (Get-Content -LiteralPath $iv -TotalCount 1).Trim()
        $a = Version-Of $t; $b = Version-Of $best
        if ($a -and (-not $b -or $a -gt $b)) { $best = $t }
    }
    return $best
}

# Setup.bat: the whole installer as a numbered menu (Noah 2026-11-17)
function Setup-Menu {
    $ver = '?'
    $vf = Join-Path $Files 'dadmod\version.txt'
    if (Test-Path -LiteralPath $vf) { $ver = (Get-Content -LiteralPath $vf -TotalCount 1).Trim() }
    Write-Host "dadmod $ver setup"
    $g = Find-Game
    while ($true) {
        $what = 'THUG Pro'
        if (Is-Kali $g) { $what = 'THUG Pro, Kali Mod detected' }
        Write-Host ''
        Write-Host "Game folder: $g ($what)"
        if ((Ask 'Is this the right game folder?' @('Yes', 'Pick another folder')) -eq 1) { break }
        $g = Pick-Folder
    }
    while (Game-Running $g) {
        if ((Ask 'THUG Pro is running. Close it first.' @('I closed it', 'Quit')) -eq 2) { exit 0 }
    }
    # a newer dadmod on GitHub? (quietly skipped when there's no internet or no release yet)
    Write-Host ''
    Write-Host 'Checking for a newer dadmod...'
    $u = Check-Update (Have-Version $g $ver)
    if ($u.state -eq 'newer') {
        Write-Host $u.text -ForegroundColor Green
        if ((Ask 'Download and install it now?' @('Yes, update now', 'Not now')) -eq 1) {
            [void](Get-Update $u $g)
            Write-Host ''
            Write-Host 'Press any key to close.'
            try { [void][Console]::ReadKey($true) } catch { }
            return
        }
    } elseif ($u.state -eq 'same') {
        Write-Host $u.text
    } elseif ($u.state -eq 'limit') {
        Write-Host $u.text
    }
    $installed = Test-Path -LiteralPath (Join-Path $g 'dadmod\install.json')
    $first = 'Install dadmod'
    if ($installed) { $first = 'Update dadmod' }
    switch (Ask 'What do you want to do?' @($first, 'Repair (put back missing maps and files)', 'Uninstall dadmod', 'Check for updates', 'Quit')) {
        1 { Install $g }
        2 { Install $g $true }
        3 { if ((Ask 'Remove dadmod from this game?' @('Yes, uninstall', 'No')) -eq 1) { Uninstall $g } else { return } }
        4 {
            Write-Host 'Checking GitHub for a newer dadmod...'
            $u = Check-Update (Have-Version $g $ver)
            Write-Host $u.text
            if ($u.state -eq 'newer' -and (Ask 'Download and install it now?' @('Yes, update now', 'Not now')) -eq 1) { [void](Get-Update $u $g) }
        }
        default { return }
    }
    Write-Host ''
    Write-Host 'Press any key to close.'
    try { [void][Console]::ReadKey($true) } catch { }
}

function Game-Running($g) {
    $exe = (Join-Path $g 'THUGPro.exe').ToLower()
    foreach ($p in Get-Process -Name THUGPro -ErrorAction SilentlyContinue) {
        try { if ($p.Path -and $p.Path.ToLower() -eq $exe) { return $true } } catch { }
    }
    return $false
}

function Menu-Archives($g) {
    $list = Join-Path $g 'dadmod\menulevels\list.txt'
    if (-not (Test-Path -LiteralPath $list)) { return @() }
    $out = @()
    foreach ($l in Get-Content -LiteralPath $list) {
        $f = ($l.Trim() -split '\s+')[0]
        if ($f -and -not $f.StartsWith('#')) { $out += "data\pre\$f" }
    }
    return $out
}

# Levels the player may already have under another custom level name: a User\*.level.dat (not ours) that points at the
# same level folder (levels\<scene>\<scene>.qb). Then ours would only add a second, identical entry to Imported Levels.
function Other-LevelDat($g, $scene, $ourDat) {
    $user = Join-Path $g 'User'
    if (-not (Test-Path -LiteralPath $user)) { return $null }
    $needle = ('levels\' + $scene + '\' + $scene + '.qb').ToLower()
    foreach ($d in Get-ChildItem -LiteralPath $user -Filter '*.level.dat' -File -ErrorAction SilentlyContinue) {
        if ($d.Name.ToLower() -eq $ourDat.ToLower()) { continue }
        try { $s = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($d.FullName)).ToLower() } catch { continue }
        if ($s.Contains($needle)) { return $d.Name }
    }
    return $null
}

function Install($g, [bool]$repair = $false) {
    if (-not (Test-Path -LiteralPath (Join-Path $Files 'binkw32.dll'))) { Fail "the package is missing files\binkw32.dll (unzip the whole package first)" }
    $dadmod = Join-Path $g 'dadmod'
    $log = Join-Path $dadmod 'install.json'
    $state = $null
    if (Test-Path -LiteralPath $log) { $state = Get-Content -LiteralPath $log -Raw | ConvertFrom-Json }
    if ($repair -and -not $state) { Fail "dadmod isn't installed in $g yet (no dadmod\install.json). Pick Install in Setup.bat instead." }
    if ($repair) { Say 'Repair: checking every dadmod file and extra level.' }
    # before anything changes: our script archive has to build from this game's own files
    $qbr = Join-Path (Split-Path -Parent $Here) 'recipes\dadmod_qb.dpr'
    if (Test-Path -LiteralPath $qbr) {
        if (-not ('DadmodRecipes' -as [type])) { Add-Type -Path (Join-Path $Here 'recipes.cs') }
        $tp0 = $null
        if ([DadmodRecipes]::Apply($qbr, $g, [ref]$tp0) -eq $null) {
            Fail 'this THUG Pro install has script files dadmod does not know (not plain THUG Pro or a known Kali Mod version). Nothing was changed.'
        }
    }
    $qb = Md5 (Join-Path $g 'data\pre\thugpro_qb.prx')
    $kind = 'THUG Pro with changed scripts (another mod)'
    if ($qb.StartsWith('1b9981f2')) { $kind = 'THUG Pro' } elseif (Is-Kali $g) { $kind = 'Kali Mod' }
    $ver = '?'
    $vf = Join-Path $Files 'dadmod\version.txt'
    if (Test-Path -LiteralPath $vf) { $ver = (Get-Content -LiteralPath $vf -TotalCount 1).Trim() }
    Say "dadmod $ver"
    Say "Game folder: $g ($kind)"
    # a server build of dadmod (or another menu mod) already has menu archives we would write over
    if (-not $state) {
        $mine = @(Get-ChildItem -LiteralPath (Join-Path $g 'data\pre') -Filter 'mainmenu_*_scripts.prx' -ErrorAction SilentlyContinue)
        if ($mine.Count -gt 0) { Fail "this folder already has main menu scene files (data\pre\mainmenu_*_scripts.prx), so it already runs the full dadmod or another menu mod. Install into a plain THUG Pro or Kali Mod folder." }
    }
    $bink = Join-Path $g 'binkw32.dll'
    $orig = Join-Path $g 'binkw32_orig.dll'
    $renamed = $false
    if ($state) { $renamed = [bool]$state.renamed_binkw32 }
    if (-not (Test-Path -LiteralPath $bink)) { Fail 'binkw32.dll is missing from the game folder (the game needs it; reinstall THUG Pro)' }
    if (Is-Ours $bink) {
        if (-not (Test-Path -LiteralPath $orig)) { Fail 'binkw32_orig.dll is missing; put the game''s own binkw32.dll back (reinstall THUG Pro) and run this again' }
        $old = '?'
        if ($state -and $state.dadmod_version) { $old = $state.dadmod_version }
        Say "Updating dadmod (installed: $old)."
    } elseif (Test-Path -LiteralPath $orig) {
        if ($state -and ((Md5 $bink) -eq (Md5 $orig))) {
            Say 'The game''s binkw32.dll came back (a game update?); putting dadmod''s back.'
        } else {
            Fail 'binkw32_orig.dll already exists and is not from dadmod, so another mod uses the same trick. Uninstall it first.'
        }
    } else {
        Move-Item -LiteralPath $bink -Destination $orig
        $renamed = $true
        Say 'Renamed binkw32.dll to binkw32_orig.dll (dadmod passes everything through to it).'
    }
    New-Item -ItemType Directory -Force -Path $dadmod | Out-Null
    $added = New-Object System.Collections.ArrayList
    $src = (Resolve-Path -LiteralPath $Files).Path
    # the extra levels' files (installer\vault_levels.txt: "<path> <md5>"): a copy the player already had stays theirs,
    # untouched and unlisted (same file: kept; a different version: kept too, and named in the summary)
    $vault = @{}
    $vl = Join-Path $Here 'vault_levels.txt'
    if (Test-Path -LiteralPath $vl) {
        foreach ($l in Get-Content -LiteralPath $vl) {
            $p = $l.Trim() -split '\s+'
            if ($p[0]) { $vault[$p[0].ToLower()] = $(if ($p.Count -gt 1) { $p[1].ToLower() } else { '' }) }
        }
    }
    $before = @{}
    if ($state) { foreach ($r in @($state.files)) { if ($r) { $before[$r.ToLower()] = $true } } }
    $kept = 0
    $restored = New-Object System.Collections.ArrayList
    $otherVer = New-Object System.Collections.ArrayList
    $dupNames = New-Object System.Collections.ArrayList
    $customToo = New-Object System.Collections.ArrayList
    foreach ($f in Get-ChildItem -LiteralPath $src -Recurse -File) {
        $rel = $f.FullName.Substring($src.Length).TrimStart('\')
        $low = $rel.ToLower()
        $dst = Join-Path $g $rel
        if ($vault.ContainsKey($low) -and -not $before[$low] -and (Test-Path -LiteralPath $dst)) {
            $kept++
            if ($vault[$low] -and ((Md5 $dst) -ne $vault[$low])) { [void]$otherVer.Add($rel) }
            continue
        }
        # a custom level (User\<scene>.level.dat) the player already has under another name: don't add a second entry
        if ($vault.ContainsKey($low) -and $rel -match '^user\\([^\\]+)\.level\.dat$' -and -not $before[$low]) {
            $other = Other-LevelDat $g $Matches[1] (Split-Path -Leaf $rel)
            if ($other) { [void]$dupNames.Add("$($Matches[1]) (you have it as User\$other)"); $kept++; continue }
        }
        # a built-in extra level the player also has as a custom map (User\data\pre\<scene>scn.prx): both work; just say so
        if ($vault.ContainsKey($low) -and $rel -match '^data\\pre\\(.+)scn\.prx$') {
            if (Test-Path -LiteralPath (Join-Path $g ('User\data\pre\' + (Split-Path -Leaf $rel)))) { [void]$customToo.Add($Matches[1]) }
        }
        if (-not (Test-Path -LiteralPath $dst) -and ($before[$low] -or ($repair -and $vault.ContainsKey($low)))) { [void]$restored.Add($rel) }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
        # custom levels (User\...): stamp them new so the game's level scan (it skips when nothing in User is newer
        # than its level list) picks them up on the next start
        if ($rel.ToLower().StartsWith('user\')) { (Get-Item -LiteralPath $dst).LastWriteTime = Get-Date }
        [void]$added.Add($rel)
    }
    # files built from the player's own game files (recipes\*.dpr, tools/dadpatch.py): our script archive, the Edit
    # Skater file and the main menu scenes carry no THUG Pro / Kali bytes; each is rebuilt here, byte for byte
    $rdir = Join-Path (Split-Path -Parent $Here) 'recipes'
    if (Test-Path -LiteralPath $rdir) {
        if (-not ('DadmodRecipes' -as [type])) { Add-Type -Path (Join-Path $Here 'recipes.cs') }
        $built = 0
        $failed = New-Object System.Collections.ArrayList
        foreach ($r in Get-ChildItem -LiteralPath $rdir -Filter '*.dpr' -File -Recurse) {
            $tp = $null
            $bytes = [DadmodRecipes]::Apply($r.FullName, $g, [ref]$tp)
            if ($bytes -eq $null) { [void]$failed.Add($tp); continue }
            $dst = Join-Path $g $tp
            if (-not (Test-Path -LiteralPath $dst) -and $before[$tp.ToLower()]) { [void]$restored.Add($tp) }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            [IO.File]::WriteAllBytes($dst, $bytes)
            [void]$added.Add($tp)
            $built++
        }
        if ($failed.Count) {
            Say "Couldn't build $($failed.Count) files from your game files (your THUG Pro version isn't one dadmod knows):"
            foreach ($t in $failed) { Say "  $t" }
            if ($failed | Where-Object { $_ -match 'dadmod_qb\.prx$' }) { Fail 'dadmod needs its script file. Please report your THUG Pro version.' }
        }
    }
    # default settings (dadmod\defaults\): only for a player who has none of their own yet
    $defs = Join-Path $dadmod 'defaults'
    if (Test-Path -LiteralPath $defs) {
        foreach ($f in Get-ChildItem -LiteralPath $defs -File) {
            $t = Join-Path $dadmod $f.Name
            if (-not (Test-Path -LiteralPath $t)) { Copy-Item -LiteralPath $f.FullName -Destination $t }
        }
    }
    # the DLL rebuilds the menu scenes on the next start (they include the game's own skate shop scripts)
    $built = Join-Path $dadmod 'menulevels\built.txt'
    if (Test-Path -LiteralPath $built) { Remove-Item -LiteralPath $built -Force }
    $info = [ordered]@{
        version = 1
        dadmod_version = $ver
        installed = (Get-Date).ToString('s')
        game_kind = $kind
        thugpro_qb_md5 = $qb
        renamed_binkw32 = $renamed
        files = @($added)
    }
    # the dadmod-install folder this came from, so the game's updater can keep it on the new version too
    if ($Pkg -and (Test-Path -LiteralPath (Join-Path $Pkg 'Setup.bat'))) { $info['package_dir'] = (Resolve-Path -LiteralPath $Pkg).Path }
    elseif ($state -and $state.package_dir) { $info['package_dir'] = $state.package_dir }
    $info | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $log -Encoding UTF8
    if ($kept) { Say "Kept $kept level files you already had (yours are used, nothing of yours was replaced)." }
    if ($otherVer.Count) {
        Say 'These level files you already had are a different version than dadmod''s. Yours were kept:'
        foreach ($r in $otherVer) { Say "  $r" }
        Say '  If one of those levels doesn''t load right, delete your copy and run Setup.bat > Repair to get dadmod''s.'
    }
    if ($dupNames.Count) {
        Say 'Already in your custom maps under another name, so dadmod didn''t add a second copy:'
        foreach ($r in $dupNames) { Say "  $r" }
    }
    if ($customToo.Count) {
        Say ('Also in your custom maps (Imported Levels): ' + ($customToo -join ', ') + '. dadmod''s built-in copy fills its level slot; you can keep or delete the custom one.')
    }
    if ($repair) {
        if ($restored.Count) {
            Say "Put back $($restored.Count) missing files:"
            foreach ($r in $restored) { Say "  $r" }
        } else { Say 'Nothing was missing.' }
        Say 'Repair done. Start THUG Pro as usual.'
    } else {
        if ($restored.Count) { Say "Put back $($restored.Count) missing files." }
        Say "Installed $($added.Count) files. Start THUG Pro as usual; the first start takes a few seconds longer while the menu scenes are set up."
    }
}

function Uninstall($g) {
    $dadmod = Join-Path $g 'dadmod'
    $log = Join-Path $dadmod 'install.json'
    if (-not (Test-Path -LiteralPath $log)) { Fail "dadmod isn't installed in $g (no dadmod\install.json)" }
    $state = Get-Content -LiteralPath $log -Raw | ConvertFrom-Json
    $bink = Join-Path $g 'binkw32.dll'
    $orig = Join-Path $g 'binkw32_orig.dll'
    $gone = 0
    foreach ($rel in @(Menu-Archives $g) + @($state.files) + @('dadmod\menulevels\built.txt')) {
        if ($rel -eq 'binkw32.dll') { continue }
        $p = Join-Path $g $rel
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; $gone++ }
    }
    $ml = Join-Path $dadmod 'menulevels'
    if ((Test-Path -LiteralPath $ml) -and -not (Get-ChildItem -LiteralPath $ml -Force)) { Remove-Item -LiteralPath $ml -Force }
    # folders the extra levels' sounds made (data\sounds\heaven, data\sounds\SanFranStreets\sfx) go once they're empty;
    # the game's own data, data\pre and data\sounds always stay
    # likewise the custom level folders it made (User\Data\Levels\Philly etc.); User and User\Data\Levels always stay
    $keepDirs = @('data', 'data\pre', 'data\sounds', 'User', 'User\Data', 'User\Data\Levels') | ForEach-Object { (Join-Path $g $_).ToLower() }
    foreach ($rel in @($state.files)) {
        if (-not $rel -or -not ($rel.ToLower().StartsWith('data\sounds\') -or $rel.ToLower().StartsWith('user\data\levels\'))) { continue }
        $d = Split-Path -Parent (Join-Path $g $rel)
        while ($d -and ($keepDirs -notcontains $d.ToLower()) -and (Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force)) {
            Remove-Item -LiteralPath $d -Force
            $d = Split-Path -Parent $d
        }
    }
    if (Is-Ours $bink) {
        if (Test-Path -LiteralPath $orig) {
            Remove-Item -LiteralPath $bink -Force
            Move-Item -LiteralPath $orig -Destination $bink
            Say 'Put the game''s own binkw32.dll back.'
        } else {
            Fail 'binkw32_orig.dll is missing, so the game''s own binkw32.dll can''t be put back; reinstall THUG Pro'
        }
    } elseif ((Test-Path -LiteralPath $orig) -and $state.renamed_binkw32) {
        # the game's binkw32.dll came back on its own (an update); ours is already gone
        if ((Md5 $bink) -eq (Md5 $orig)) { Remove-Item -LiteralPath $orig -Force }
    }
    Move-Item -LiteralPath $log -Destination (Join-Path $dadmod ('install.json.removed_' + (Get-Date).ToString('yyyyMMdd_HHmmss')))
    Say "Removed $gone dadmod files. Your settings are still in $dadmod (delete that folder if you don't want them)."
    Say "The dadmod-install folder stays, so you can install again with its Setup.bat."
}

# (No longer called: Noah 2026-11-17 wants Uninstall to keep the dadmod-install folder.) The unzipped package
# (dadmod-install: the .bat files, README.txt, installer\, files\) went too, this script included. Only our own items are removed, and the folder itself only once it's empty. It runs from a hidden cmd
# that waits a moment, so this script and Uninstall dadmod.bat have finished when their files go.
function Remove-Package {
    $pkg = $Pkg
    $ours = (Test-Path -LiteralPath (Join-Path $pkg 'Setup.bat')) -and (Is-Ours (Join-Path $Files 'binkw32.dll'))
    if ($ours) { Say "The installer folder $pkg is deleted when you close this window." }
    Say ''
    Write-Host 'Press any key to close.'
    try { [void][Console]::ReadKey($true) } catch { }
    if (-not $ours) { return }
    $q = { param($p) '"' + $p + '"' }
    $cmd = 'ping -n 3 127.0.0.1 >nul'
    foreach ($f in @('Setup.bat', 'files.dad', 'dadmod Setup.bat', 'dadmod.dpk', 'Install dadmod.bat', 'Uninstall dadmod.bat', 'Repair dadmod.bat', 'INSTALL.txt', 'README.txt')) { $cmd += ' & del /f /q ' + (& $q (Join-Path $pkg $f)) }
    foreach ($d in @('installer', 'files')) { $cmd += ' & rmdir /s /q ' + (& $q (Join-Path $pkg $d)) }
    $cmd += ' & rmdir ' + (& $q $pkg)
    Start-Process -FilePath $env:ComSpec -ArgumentList ('/c "' + $cmd + '"') -WindowStyle Hidden -WorkingDirectory $env:TEMP
}

# the game's updater (Pause > dadmod > Update dadmod, or Update now on the main menu popup; Noah 2026-11-18): the game
# starts this in its own window and quits; this waits for it to close, installs the newest release, starts it again
function Game-Update($g) {
    try { $Host.UI.RawUI.WindowTitle = 'dadmod updater' } catch { }
    Say 'dadmod updater'
    Say ''
    if ($WaitPid) {
        Say 'Waiting for THUG Pro to close...'
        try { [void](Get-Process -Id $WaitPid -ErrorAction Stop).WaitForExit(60000) } catch { }
    }
    for ($n = 0; (Game-Running $g) -and $n -lt 30; $n++) { Start-Sleep -Seconds 1 }
    $exe = Join-Path $g 'THUGPro.exe'
    if (Game-Running $g) {
        Say 'THUG Pro is still open, so nothing was changed. Close it and pick Update dadmod again.'
        Write-Host 'Press any key to close.'; try { [void][Console]::ReadKey($true) } catch { }
        exit 1
    }
    # the player's dadmod-install folder: the one install.json names, else <game>\dadmod-install
    $script:Pkg = ''
    $state = $null
    try { $state = Get-Content -LiteralPath (Join-Path $g 'dadmod\install.json') -Raw | ConvertFrom-Json } catch { }
    foreach ($c in @($(if ($state) { "$($state.package_dir)" }), (Join-Path $g 'dadmod-install'))) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'Setup.bat'))) { $script:Pkg = $c; break }
    }
    Say 'Checking for a newer dadmod...'
    $u = Check-Update (Have-Version $g '')
    Say $u.text
    $ok = $false
    if ($u.state -eq 'newer') { $ok = Get-Update $u $g $Zip }
    # the game's download is used up (or out of date): remove it
    if ($Zip -and (Test-Path -LiteralPath $Zip)) { Remove-Item -LiteralPath $Zip -Force -ErrorAction SilentlyContinue }
    Say ''
    if ($ok) {
        Say 'Done. Starting THUG Pro...'
    } else {
        if ($u.state -eq 'newer') { Write-Host 'The update did not finish. Your dadmod is as it was.' -ForegroundColor Red }
        Write-Host 'Press any key to start THUG Pro again.'
        try { [void][Console]::ReadKey($true) } catch { }
    }
    Start-Process -FilePath $exe -WorkingDirectory $g
    Start-Sleep -Seconds 2
}

if ($Action -eq 'update') {
    if (-not (Is-Game $Game)) { Fail "no THUG Pro install at $Game" }
    Game-Update (Resolve-Path -LiteralPath $Game).Path
    exit 0
}
if ($Action -eq 'menu') { Setup-Menu; exit 0 }
$g = Find-Game
if (Game-Running $g) { Fail 'THUG Pro is running from this folder. Close it and run this again.' }
if ($Action -eq 'install') { Install $g } elseif ($Action -eq 'repair') { Install $g $true } else { Uninstall $g }
