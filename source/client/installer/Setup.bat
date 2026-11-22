@echo off
rem dadmod setup: install / update, repair or uninstall dadmod. Close THUG Pro first.
rem Everything it installs is in files.dad next to this file; the PowerShell part below first checks GitHub for a newer
rem dadmod (and can download it into this folder), then unpacks files.dad to a temp folder, runs the installer from there
rem and deletes the temp folder again. One line on purpose: this file can be replaced by a newer Setup.bat while it runs,
rem and cmd never reads past a line it has already started.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $s=[IO.File]::ReadAllText($f); $m='#'+'DADMOD-PS'; iex $s.Substring($s.LastIndexOf($m))" || pause & exit /b
#DADMOD-PS
$ErrorActionPreference = 'Stop'
$pkg = Split-Path -Parent $f
$dpk = Join-Path $pkg 'files.dad'
if (-not (Test-Path -LiteralPath $dpk)) { Write-Host 'files.dad is missing. Unzip the whole dadmod zip again.' -ForegroundColor Red; exit 1 }
# a newer dadmod on GitHub? Checked BEFORE unpacking (Noah 2026-11-20), so an old package isn't unpacked for nothing.
# make_client writes the package version below. Quietly skipped with no internet, no release or GitHub busy.
# DADMOD_UPDATE_URL overrides the API address (local tests).
$ver = '@DADMOD_VERSION@'
function Version-Of($t) {
    $m = [regex]::Match("$t", '\d+(\.\d+){1,3}')
    if (-not $m.Success) { return $null }
    try { return [version]$m.Value } catch { return $null }
}
$cur = Version-Of $ver
if ($cur) {
    Write-Host 'Checking for a newer dadmod...'
    $u = $null
    try {
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
        $api = $env:DADMOD_UPDATE_URL
        if (-not $api) { $api = 'https://api.github.com/repos/nrpabst/Dadmod/releases?per_page=30' }
        $req = [Net.HttpWebRequest]::Create($api)
        $req.UserAgent = 'dadmod-setup'
        $req.Accept = 'application/vnd.github+json'
        $req.Timeout = 8000
        $req.ReadWriteTimeout = 8000
        $resp = $req.GetResponse()
        $sr = New-Object IO.StreamReader($resp.GetResponseStream())
        $body = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
        # the highest version among the published releases (betas included) that carry a dadmod.zip
        # PowerShell 5.1 passes the parsed JSON array down the pipeline as ONE item, so @($body | ConvertFrom-Json)
        # would be a 1-item array holding the whole list (every release skipped): store it first, then loop
        $rels = $body | ConvertFrom-Json
        foreach ($rel in @($rels)) {
            if (-not $rel -or $rel.draft) { continue }
            $rv = Version-Of "$($rel.tag_name)"
            if (-not $rv) { $rv = Version-Of "$($rel.name)" }
            foreach ($a in @($rel.assets)) {
                if ("$($a.name)" -ieq 'dadmod.zip' -and $rv -and (-not $u -or $rv -gt $u.v)) { $u = @{ v = $rv; tag = "$($rel.tag_name)"; url = "$($a.browser_download_url)"; size = [long]$a.size } }
            }
        }
    } catch {
        $u = $null
        Write-Host 'Could not check for updates right now (no internet, or GitHub is busy). Using this package.'
    }
    if ($u -and -not ($u.v -gt $cur)) { Write-Host "This is the newest dadmod ($ver)." }
    if ($u -and $u.v -gt $cur) {
        Write-Host ''
        Write-Host "dadmod $($u.tag) is out (this package is $ver)." -ForegroundColor Green
        $pick = 0
        while ($pick -lt 1 -or $pick -gt 2) {
            Write-Host 'Download it now?'
            Write-Host '  1) Yes, download the new version'
            Write-Host '  2) Not now, use this package'
            Write-Host -NoNewline 'Press 1-2: '
            if ([Console]::IsInputRedirected) { $k = [Console]::In.ReadLine(); if ($null -eq $k) { $k = '2' } } else { try { $k = [string][Console]::ReadKey($true).KeyChar } catch { $k = Read-Host } }
            Write-Host $k
            [void][int]::TryParse("$k".Trim(), [ref]$pick)
        }
        if ($pick -eq 1) {
            $dl = Join-Path $env:TEMP ('dadmod_download_' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $dl | Out-Null
            try {
                $zip = Join-Path $dl 'dadmod.zip'
                Write-Host ("Downloading dadmod $($u.tag) ({0} MB)..." -f [math]::Round($u.size / 1MB))
                $wc = New-Object Net.WebClient
                $wc.Headers.Add('User-Agent', 'dadmod-setup')
                $wc.DownloadFile($u.url, $zip)
                if ($u.size -gt 0 -and (Get-Item -LiteralPath $zip).Length -ne $u.size) { throw 'wrong size' }
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $ux = Join-Path $dl 'zip'
                [IO.Compression.ZipFile]::ExtractToDirectory($zip, $ux)
                $nd = @(Get-ChildItem -LiteralPath $ux -Recurse -Filter 'files.dad')
                if ($nd.Count -ne 1) { throw 'no files.dad' }
                # this dadmod-install folder becomes the new version (Setup.bat too: cmd won't read this one again)
                foreach ($n in @('files.dad', 'README.txt', 'Setup.bat')) {
                    $src = Join-Path $nd[0].DirectoryName $n
                    if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $pkg $n) -Force }
                }
                Write-Host "Downloaded dadmod $($u.tag)."
            } catch {
                Write-Host 'The download did not work (internet dropped?). Using this package instead.' -ForegroundColor Yellow
            } finally {
                Remove-Item -LiteralPath $dl -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } elseif ($u) {
        Write-Host "This is the newest dadmod ($ver)."
    }
}
$tmp = Join-Path $env:TEMP ('dadmod_setup_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Write-Host 'Unpacking dadmod...'
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
    $zip = Join-Path $tmp 'pkg.zip'
    try { [DadmodPack2]::Unpack($dpk, $zip) } catch { $m = $_.Exception.Message; if ($_.Exception.InnerException) { $m = $_.Exception.InnerException.Message }; if ($m -like '*from a newer dadmod*') { $m = 'Setup.bat was just updated. Run Setup.bat again.' } else { $m += ' Unzip the whole dadmod zip again (or download it again).' }; Write-Host $m -ForegroundColor Red; exit 1 }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $x = Join-Path $tmp 'x'
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $x)
    Remove-Item -LiteralPath $zip -Force
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $x 'installer\dadmod.ps1') menu -PackageDir $pkg
    $code = $LASTEXITCODE
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
exit $code
