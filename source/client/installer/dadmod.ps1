# dadmod client installer / uninstaller (Windows PowerShell 5.1 or later).
#   Install dadmod.bat    -> dadmod.ps1 install   [-Game "<THUG Pro folder>"]
#   Uninstall dadmod.bat  -> dadmod.ps1 uninstall [-Game "<THUG Pro folder>"]
#   Repair dadmod.bat     -> dadmod.ps1 repair    [-Game "<THUG Pro folder>"]  (puts back any dadmod file or extra
#                            level that went missing, e.g. a map deleted from the custom maps folder)
#   the game (main menu > Dadmod > Updates) -> <game>\dadmod\updater\dadmod.ps1 update -Game "<game>" -WaitPid <pid>
#                            [-Zip <the game's download> -Version x -Sha256 y] [-OnQuit]
#                            (a copy of this file the package installs; waits for the game to close, updates in a
#                            small dadmod window, starts the game again unless it was Install when I quit)
# Works on a plain THUG Pro install or a Kali Mod install. It never changes a THUG Pro or Kali file:
#   - binkw32.dll is renamed binkw32_orig.dll (ours forwards every call to it) and put back on uninstall;
#   - everything else it adds is new: data\pre\dadmod_qb.prx, data\dadmod_casidle.qb, dadmod\menulevels\, and the extra
#     levels' files in data\pre and data\sounds (installer\vault_levels.txt; a copy the player already had is kept and left alone).
# What it did is written to <game>\dadmod\install.json; the uninstaller undoes exactly that. The unzipped
# dadmod-install folder stays (Noah 2026-11-17), so Setup.bat can install again from it.
# Setup.bat checks the public releases repo for a newer dadmod.zip itself, before it unpacks files.dad (Noah 2026-11-20);
# the in-game updater uses Check-Update / Get-Update below.
# Your dadmod settings (dadmod\*.ini) stay after an uninstall.
param(
    [Parameter(Position = 0)][ValidateSet('menu', 'install', 'uninstall', 'repair', 'update')][string]$Action = 'menu',
    [string]$Game = '',
    [string]$PackageDir = '',
    [int]$WaitPid = 0,
    [string]$Zip = '',
    [string]$Version = '',
    [string]$Sha256 = '',
    [switch]$OnQuit
)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
# Setup.bat unpacks files.dad to a temp folder and runs this from there; PackageDir is the folder the player
# unzipped (dadmod-install, with Setup.bat and files.dad). Without it, the package is the folder above installer\.
$Pkg = $PackageDir
if (-not $Pkg) { $Pkg = Split-Path -Parent $Here }
$Files = Join-Path (Split-Path -Parent $Here) 'files'
$Marker = 'dadmod client loader'

# the in-game updater's small window (Game-Update) and its log (dadmod\update\update.log); Setup.bat uses the console
$script:UiForm = $null; $script:UiLabel = $null; $script:UiLines = @(); $script:UpdLog = ''
function Say($t) {
    Write-Host $t
    if ($script:UpdLog) { try { Add-Content -LiteralPath $script:UpdLog -Value ((Get-Date).ToString('HH:mm:ss') + '  ' + $t) } catch { } }
    if ($script:UiLabel -and "$t".Trim()) {
        # @(...) around the whole thing: one line from Select-Object is a plain string, and the next + would glue onto it
        $script:UiLines = @(@($script:UiLines) + @("$t".Trim()) | Select-Object -Last 4)
        # drop the oldest lines until the wrapped text fits the label (long lines wrap)
        try {
            $lim = New-Object Drawing.Size($script:UiLabel.Width, 0)
            while ($script:UiLines.Count -gt 1 -and [Windows.Forms.TextRenderer]::MeasureText(($script:UiLines -join "`r`n"), $script:UiLabel.Font, $lim, [Windows.Forms.TextFormatFlags]::WordBreak).Height -gt $script:UiLabel.Height) {
                $script:UiLines = @($script:UiLines | Select-Object -Skip 1)
            }
        } catch { }
        $script:UiLabel.Text = ($script:UiLines -join "`r`n")
        Ui-Pump
    }
}
function Log-Only($t) { if ($script:UpdLog) { try { Add-Content -LiteralPath $script:UpdLog -Value ((Get-Date).ToString('HH:mm:ss') + '  ' + $t) } catch { } } }
function Ui-Pump { if ($script:UiForm) { try { [Windows.Forms.Application]::DoEvents() } catch { } } }
# the updater window's progress bar (0-100, never goes back) and the detail line under it (Noah 2026-11-24)
$script:UiBar = $null; $script:UiPct = $null; $script:UiDetail = $null; $script:UiMax = 0; $script:UiStep = ''
function Set-Progress($pct, $note) {
    if (-not $script:UiBar) { return }
    $v = [int][math]::Floor([double]$pct)
    if ($v -lt 0) { $v = 0 } elseif ($v -gt 100) { $v = 100 }
    if ($v -gt $script:UiMax) {
        $script:UiMax = $v
        try {
            # Windows animates a bar slowly up to a new value but jumps straight down, so go one past it and back
            # (the bar shows the real value at once; at 100 the maximum goes up by one for a moment)
            if ($v -ge 100) { $script:UiBar.Maximum = 101; $script:UiBar.Value = 101; $script:UiBar.Value = 100; $script:UiBar.Maximum = 100 }
            else { $script:UiBar.Value = $v + 1; $script:UiBar.Value = $v }
            $script:UiPct.Text = "$v%"
        } catch { }
    }
    if ($note) { Say $note }
    Ui-Pump
}
function Set-Detail($t) {
    if (-not $script:UiDetail) { return }
    try { $script:UiDetail.Text = "$t" } catch { }
    # the log gets each new step once (the part before ':'), so update.log shows how long each step took
    $step = ("$t" -split ':')[0]
    if ($step -ne $script:UiStep) { $script:UiStep = $step; Log-Only ("step: $t") }
    Ui-Pump
}
# progress from anywhere: the window when this is the updater, "##P n" / "##D text" lines on stdout when this is the
# installer the updater runs (DADMOD_PROGRESS=1; Run-Installer reads them), nothing for Setup.bat's console
$script:RepWatch = [Diagnostics.Stopwatch]::StartNew(); $script:RepLastP = -1
function Report($pct, $detail, [bool]$force = $false) {
    if ($script:UiBar) {
        if ($detail) { Set-Detail $detail }
        if ($pct -ne $null) { Set-Progress $pct }
        return
    }
    if ($env:DADMOD_PROGRESS -ne '1') { return }
    if (-not $force -and $script:RepWatch.ElapsedMilliseconds -lt 200) { return }
    $script:RepWatch.Restart()
    if ($pct -ne $null) {
        $v = [int][math]::Floor([double]$pct)
        if ($v -ne $script:RepLastP) { $script:RepLastP = $v; [Console]::Out.WriteLine("##P $v") }
    }
    if ($detail) { [Console]::Out.WriteLine("##D $detail") }
    [Console]::Out.Flush()
}
function Mb($b) { ([double]$b / 1MB).ToString('0.0', [Globalization.CultureInfo]::InvariantCulture) }
# MD5 of a big file with progress ($from..$to)
function Md5-Progress($p, $label, $from, $to) {
    $h = [Security.Cryptography.MD5]::Create()
    $fs = [IO.File]::OpenRead($p)
    try {
        $len = [math]::Max(1, $fs.Length); $buf = New-Object byte[] (1MB); $done = 0
        while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) {
            [void]$h.TransformBlock($buf, 0, $n, $null, 0); $done += $n
            Report ($from + ($to - $from) * $done / $len) "Checking ${label}: $(Mb $done) of $(Mb $len) MB"
        }
        [void]$h.TransformFinalBlock($buf, 0, 0)
    } finally { $fs.Close() }
    return ([BitConverter]::ToString($h.Hash) -replace '-', '').ToLower()
}
# downloads $url to $path with progress ($from..$to); throws on failure
function Download-Progress($url, $path, $label, $from, $to) {
    $req = [Net.HttpWebRequest]::Create($url)
    $req.UserAgent = 'dadmod-setup'
    $req.Timeout = 30000; $req.ReadWriteTimeout = 30000
    $resp = $req.GetResponse()
    try {
        $total = $resp.ContentLength
        $in = $resp.GetResponseStream()
        $out = [IO.File]::Create($path)
        try {
            $buf = New-Object byte[] (64KB); $done = 0; $sw = [Diagnostics.Stopwatch]::StartNew()
            while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
                $out.Write($buf, 0, $n); $done += $n
                $sec = [math]::Max(0.001, $sw.Elapsed.TotalSeconds)
                $rate = $done / $sec
                $d = "Downloading ${label}: $(Mb $done)"
                if ($total -gt 0) {
                    $d += " of $(Mb $total) MB"
                    if ($sec -ge 1) {
                        $left = ($total - $done) / [math]::Max(1, $rate)
                        $lt = $(if ($left -ge 90) { "about $([math]::Ceiling($left / 60)) min left" } elseif ($left -ge 10) { "about $([math]::Ceiling($left / 10) * 10) s left" } else { 'a few seconds left' })
                        $d += " ($(Mb $rate) MB/s, $lt)"
                    }
                    Report ($from + ($to - $from) * $done / $total) $d
                } else { Report $null ($d + ' MB') }
            }
        } finally { $out.Close(); $in.Close() }
    } finally { $resp.Close() }
}
# files.dad -> zip on a worker runspace, with progress ($from..$to) from how much of files.dad has been read: this
# process's read byte count (GetProcessIoCounters; nothing else reads much meanwhile). DadmodPack2 itself stays the
# same text as installer\DadmodPack2.cs and Setup.bat's copy, and files.dad's LZMA header has no size (-1).
function Io-Read {
    if (-not ('DadmodIo' -as [type])) {
        Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class DadmodIo {
    [StructLayout(LayoutKind.Sequential)] struct IO_COUNTERS { public ulong r, w, o, rb, wb, ob; }
    [DllImport("kernel32.dll")] static extern bool GetProcessIoCounters(IntPtr h, out IO_COUNTERS c);
    [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
    public static long ReadBytes() { IO_COUNTERS c; return GetProcessIoCounters(GetCurrentProcess(), out c) ? (long)c.rb : 0; }
}
'@
    }
    return [DadmodIo]::ReadBytes()
}
function Unpack-Progress($src, $dst, $label, $from, $to) {
    Use-Pack2
    $tot = [math]::Max(1, (Get-Item -LiteralPath $src).Length)
    $io0 = 0; try { $io0 = Io-Read } catch { }
    $ps = [PowerShell]::Create()
    [void]$ps.AddScript('param($a, $b) [DadmodPack2]::Unpack($a, $b)').AddArgument($src).AddArgument($dst)
    $ar = $ps.BeginInvoke()
    try {
        while (-not $ar.IsCompleted) {
            Start-Sleep -Milliseconds 100
            $r = 0; try { $r = (Io-Read) - $io0 } catch { }
            if ($r -gt $tot) { $r = $tot } elseif ($r -lt 0) { $r = 0 }
            Report ($from + ($to - $from) * $r / $tot) "Unpacking ${label}: $(Mb $r) of $(Mb $tot) MB"
            Ui-Pump
        }
        [void]$ps.EndInvoke($ar)
        if ($ps.Streams.Error.Count) {
            $ex = $ps.Streams.Error[0].Exception
            while ($ex.InnerException) { $ex = $ex.InnerException }
            throw $ex
        }
    } finally { $ps.Dispose() }
    Report $to "Unpacking ${label}: $(Mb $tot) of $(Mb $tot) MB" $true
}
function Fail($t) { Write-Host ''; Write-Host "Stopped: $t" -ForegroundColor Red; exit 1 }

function Is-Game($p) { $p -and (Test-Path -LiteralPath (Join-Path $p 'THUGPro.exe')) -and (Test-Path -LiteralPath (Join-Path $p 'data\pre\thugpro_qb.prx')) }

function Is-Ours($dll) {
    if (-not (Test-Path -LiteralPath $dll)) { return $false }
    $b = [IO.File]::ReadAllBytes($dll)
    $s = [Text.Encoding]::ASCII.GetString($b)
    return $s.Contains($Marker)
}

function Md5($p) { (Get-FileHash -LiteralPath $p -Algorithm MD5).Hash.ToLower() }
function Md5Text($t) { $h = [Security.Cryptography.MD5]::Create(); (($h.ComputeHash([Text.Encoding]::UTF8.GetBytes("$t")) | ForEach-Object { $_.ToString('x2') }) -join '') }

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

# Kali Mod: its scripts carry the "Kalimod" name. Some Kali setups also have data\pre\thugpro_qe.prx (a stock copy
# that a patched thugpro.dll reads), but the public Kali download has none, so dadmod never needs it
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
        # one key press picks (no Enter; Noah 2026-11-17); with piped input, one line per answer, and stop when that
        # input runs out instead of asking forever (Noah 2026-11-21)
        Write-Host -NoNewline ('Press 1-' + $choices.Count + ': ')
        $a = $null
        if ([Console]::IsInputRedirected) {
            $a = [Console]::In.ReadLine()
            if ($null -eq $a) { Write-Host ''; Write-Host 'No more key presses to read, so setup stopped.'; exit 1 }
        } else { try { $a = [string][Console]::ReadKey($true).KeyChar } catch { $a = Read-Host } }
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

# the files.dad / map pack reader (DADMODPK1 or the LZMA DADMODPK2); Get-Update and the map packs use it
function Use-Pack2 {
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
            try { Download-Progress $u.url $zip "dadmod $($u.tag)" 0 2 } catch { Say 'The download failed (internet dropped?). Nothing was changed. Try again later.'; return $false }
        }
        if ($u.size -gt 0 -and (Get-Item -LiteralPath $zip).Length -ne $u.size) { $script:ZipBad = $true; Say 'The download came out the wrong size. Nothing was changed. Try again later.'; return $false }
        Report 2 "Checking the download: $(Mb (Get-Item -LiteralPath $zip).Length) MB" $true
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $x = Join-Path $tmp 'zip'
        Report 2 "Extracting the download: $(Mb (Get-Item -LiteralPath $zip).Length) MB" $true
        try { [IO.Compression.ZipFile]::ExtractToDirectory($zip, $x) } catch { $script:ZipBad = $true; Say 'The downloaded zip is damaged. Nothing was changed. Try again later.'; return $false }
        Report 4 $null $true
        $dad = @(Get-ChildItem -LiteralPath $x -Recurse -Filter 'files.dad')
        if ($dad.Count -ne 1) { $script:ZipBad = $true; Say 'The downloaded zip has no files.dad. Nothing was changed.'; return $false }
        $src = $dad[0].DirectoryName
        # unpack the new files.dad (same reader as Setup.bat: DADMODPK1 or the LZMA DADMODPK2) and run its installer
        $inner = Join-Path $tmp 'pkg.zip'
        try { Unpack-Progress $dad[0].FullName $inner 'dadmod' 4 10 } catch { $script:ZipBad = $true; Say 'The downloaded files.dad is damaged. Nothing was changed.'; return $false }
        $nx = Join-Path $tmp 'x'
        # the package's files, one by one so the window can count them
        $za = [IO.Compression.ZipFile]::OpenRead($inner)
        try {
            $ents = @($za.Entries); $i = 0
            $root = [IO.Path]::GetFullPath($nx).TrimEnd('\') + '\'
            foreach ($e in $ents) {
                $i++
                $dst = [IO.Path]::GetFullPath((Join-Path $nx $e.FullName))
                if (-not $dst.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { continue }
                if ($e.FullName.EndsWith('/')) { New-Item -ItemType Directory -Force -Path $dst | Out-Null; continue }
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
                [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dst, $true)
                Report (10 + 2 * $i / $ents.Count) "Extracting dadmod: $i of $($ents.Count) files"
            }
        } finally { $za.Dispose() }
        Report 12 "Extracting dadmod: $($ents.Count) of $($ents.Count) files" $true
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
        return (Run-Installer $ia $tmp)
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 64-bit Windows PowerShell when there is one (a 32-bit PowerShell can run out of memory unpacking the big map pack)
function PowerShell-Exe {
    $sn = Join-Path $env:windir 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $sn) { return $sn }
    return (Join-Path $PSHOME 'powershell.exe')
}

# runs the new package's installer; with the updater window up, its output goes to the window line by line
function Run-Installer($ia, $tmp) {
    $ps = PowerShell-Exe
    if (-not $script:UiForm) {
        & $ps @ia | Out-Host
        return ($LASTEXITCODE -eq 0)
    }
    $out = Join-Path $tmp 'install_out.txt'
    $err = Join-Path $tmp 'install_err.txt'
    $q = ($ia | ForEach-Object { if ("$_" -match '[\s"]') { '"' + ("$_" -replace '"', '\"') + '"' } else { "$_" } }) -join ' '
    # the installer reports "##P <0-100>" and "##D <detail>" lines for the bar (only this child gets the variable)
    $env:DADMOD_PROGRESS = '1'
    try { $p = Start-Process -FilePath $ps -ArgumentList $q -RedirectStandardOutput $out -RedirectStandardError $err -WindowStyle Hidden -PassThru }
    finally { Remove-Item Env:\DADMOD_PROGRESS -ErrorAction SilentlyContinue }
    $line = {
        param($ln)
        if ($ln -match '^##P (\d+)\s*$') { Set-Progress (12 + [int]$Matches[1] * 0.88) }
        elseif ($ln.StartsWith('##D ')) { Set-Detail $ln.Substring(4) }
        else { Say $ln }
    }
    [void]$p.Handle   # keeps the exit code readable after it ends
    $pos = 0; $rest = ''
    $read = {
        try {
            $fs = New-Object IO.FileStream($out, 'Open', 'Read', 'ReadWrite')
            try {
                if ($fs.Length -gt $pos) {
                    [void]$fs.Seek($pos, 'Begin')
                    $buf = New-Object byte[] ($fs.Length - $pos)
                    $n = $fs.Read($buf, 0, $buf.Length)
                    $script:rdPos = $pos + $n
                    $script:rdText = $rest + [Text.Encoding]::Default.GetString($buf, 0, $n)
                } else { $script:rdPos = $pos; $script:rdText = $rest }
            } finally { $fs.Close() }
        } catch { $script:rdPos = $pos; $script:rdText = $rest }
    }
    while ($true) {
        $done = $p.HasExited
        . $read
        $pos = $script:rdPos
        $parts = $script:rdText -split "`n"
        $rest = $parts[-1]
        foreach ($ln in $parts[0..($parts.Count - 2)]) { if ($parts.Count -gt 1) { & $line ($ln.TrimEnd("`r")) } }
        if ($done) { break }
        Ui-Pump
        Start-Sleep -Milliseconds 100
    }
    if ($rest.Trim()) { & $line $rest.TrimEnd("`r") }
    try { foreach ($ln in @(Get-Content -LiteralPath $err -ErrorAction SilentlyContinue)) { if ("$ln".Trim()) { Say "$ln" } } } catch { }
    return ($p.ExitCode -eq 0)
}

# the updater's small window: what it is doing, a moving bar, no console (2026-11-24)
function Show-UpdateWindow($title) {
    try {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        [Windows.Forms.Application]::EnableVisualStyles()
        $f = New-Object Windows.Forms.Form
        $f.Text = $title
        $f.ClientSize = New-Object Drawing.Size(460, 162)
        $f.FormBorderStyle = 'FixedDialog'
        $f.MaximizeBox = $false
        $f.ControlBox = $false
        $f.StartPosition = 'CenterScreen'
        $f.TopMost = $true
        $f.ShowInTaskbar = $true
        $l = New-Object Windows.Forms.Label
        $l.SetBounds(16, 12, 428, 74)
        $l.Font = New-Object Drawing.Font('Segoe UI', 9.5)
        # a real bar (Noah 2026-11-24): 0-100 with the percent on its right and the current step's details under it
        $b = New-Object Windows.Forms.ProgressBar
        $b.SetBounds(16, 94, 384, 18)
        $b.Style = 'Continuous'
        $b.Minimum = 0; $b.Maximum = 100; $b.Value = 0
        $pc = New-Object Windows.Forms.Label
        $pc.SetBounds(402, 94, 42, 18)
        $pc.TextAlign = 'MiddleRight'
        $pc.Font = New-Object Drawing.Font('Segoe UI', 9.5, [Drawing.FontStyle]::Bold)
        $pc.Text = '0%'
        $d = New-Object Windows.Forms.Label
        $d.SetBounds(16, 118, 428, 36)
        $d.Font = New-Object Drawing.Font('Segoe UI', 8.75)
        $d.ForeColor = [Drawing.Color]::FromArgb(80, 80, 80)
        $f.Controls.Add($l); $f.Controls.Add($b); $f.Controls.Add($pc); $f.Controls.Add($d)
        $f.Show()
        $script:UiForm = $f; $script:UiLabel = $l; $script:UiBar = $b; $script:UiPct = $pc; $script:UiDetail = $d; $script:UiMax = 0
        Ui-Pump
    } catch { $script:UiForm = $null; $script:UiLabel = $null; $script:UiBar = $null; $script:UiPct = $null; $script:UiDetail = $null }
}
function Close-UpdateWindow { if ($script:UiForm) { try { $script:UiForm.Close() } catch { }; $script:UiForm = $null; $script:UiLabel = $null; $script:UiBar = $null; $script:UiPct = $null; $script:UiDetail = $null } }
function Update-Message($text, $bad) {
    if ($script:UiForm) {
        Close-UpdateWindow
        $icon = $(if ($bad) { [Windows.Forms.MessageBoxIcon]::Warning } else { [Windows.Forms.MessageBoxIcon]::Information })
        [void][Windows.Forms.MessageBox]::Show($text, 'dadmod updater', [Windows.Forms.MessageBoxButtons]::OK, $icon)
    } else {
        Write-Host $text
        Write-Host 'Press any key to close.'; try { [void][Console]::ReadKey($true) } catch { }
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
    # the update check runs in Setup.bat before files.dad is unpacked (Noah 2026-11-20), so there's none here and no
    # "Check for updates" choice. "Update" only when this package is newer than what's installed.
    $first = 'Install dadmod'
    if (Test-Path -LiteralPath (Join-Path $g 'dadmod\install.json')) {
        $first = 'Reinstall dadmod'
        $iv = Join-Path $g 'dadmod\version.txt'
        $inst = $null
        if (Test-Path -LiteralPath $iv) { $inst = (Get-Content -LiteralPath $iv -TotalCount 1).Trim() }
        $a = Version-Of $inst; $b = Version-Of $ver
        if ($b -and (-not $a -or $b -gt $a)) { $first = "Update dadmod to $ver" }
        elseif ($a -and $b -and $b -lt $a) { $first = "Reinstall dadmod (this package is $ver, older than your $inst)" }
    }
    switch (Ask 'What do you want to do?' @($first, 'Repair (put back missing maps and files)', 'Uninstall dadmod', 'Quit')) {
        1 { Install $g }
        2 { Install $g $true }
        3 { if ((Ask 'Remove dadmod from this game?' @('Yes, uninstall', 'No')) -eq 1) { Uninstall $g } else { return } }
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

# plain-English reasons from a recipe check (Noah 2026-11-18: the installer has to say why it stopped). Reads the
# "closest is version" part of DadmodRecipes.Diagnose: one reason per game file that is missing or different
function Explain-Problem($text) {
    $out = New-Object System.Collections.ArrayList
    $seen = @{}
    $after = $false
    $noThug2 = $text -match 'thug2_path\): \(not set\)'
    foreach ($l in ($text -split "`r?`n")) {
        if ($l -like 'closest is version*') { $after = $true; continue }
        if (-not $after) { continue }
        if ($l -notmatch '^\s+(MISSING|DIFFERENT|UNREADABLE) (.+?) : ') { continue }
        $how = $matches[1]; $f = $matches[2]
        if ($seen.ContainsKey($f.ToLower())) { continue }
        $seen[$f.ToLower()] = 1
        $leaf = Split-Path -Leaf ($f -replace '^thug2:', '')
        if ($f -like 'thug2:*') {
            if ($noThug2) { $w = "THUG Pro doesn't know where THUG2 is installed, so dadmod can't read THUG2's $leaf. Open the THUG Pro launcher and set your THUG2 folder, then run Setup again." }
            elseif ($how -eq 'MISSING') { $w = "THUG2's $leaf is missing from your THUG2 folder. Check the THUG2 folder set in the THUG Pro launcher." }
            else { $w = "THUG2's $leaf isn't the normal THUG2 file (another mod may have changed your THUG2)." }
        } elseif ($leaf -ieq 'thugpro_qb.prx') {
            if ($how -eq 'MISSING') { $w = "data\pre\thugpro_qb.prx is missing. Reinstall THUG Pro or Kali Mod." }
            else { $w = "Your THUG Pro scripts (data\pre\thugpro_qb.prx) are a version dadmod doesn't know yet, for example a newer Kali Mod or another mod." }
        } elseif ($leaf -ieq 'thugpro_qe.prx') {
            $w = "data\pre\thugpro_qe.prx is missing or different (it comes with some Kali Mod copies)."
        } elseif ($leaf -ieq 'Skateshop_scripts.prx') {
            $w = "Your skate shop scripts (data\pre\Skateshop_scripts.prx) were changed, usually by a Create-a-Skater (CAS) mod."
        } elseif ($how -eq 'MISSING') {
            $w = "$f is missing from your game."
        } else {
            $w = "$f was changed by another mod."
        }
        [void]$out.Add($w)
    }
    return ,$out
}

# a report the player can send when the game files don't match a known version (Noah 2026-11-18). Written next to
# Setup.bat (or to the Desktop when that folder is read-only); never into the game folder
function Write-Problem($g, $recipes, $head = 'Why it stopped:') {
    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("dadmod install problem report, " + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
    $vf = Join-Path $Files 'dadmod\version.txt'
    if (Test-Path -LiteralPath $vf) { [void]$lines.Add('dadmod ' + (Get-Content -LiteralPath $vf -TotalCount 1).Trim()) }
    [void]$lines.Add("Game folder: $g")
    foreach ($f in @('THUGPro.exe', 'thugpro.dll', 'binkw32.dll', 'binkw32_orig.dll', 'data\pre\thugpro_qb.prx', 'data\pre\thugpro_qe.prx', 'data\pre\Skateshop_scripts.prx')) {
        $fp = Join-Path $g $f
        if (Test-Path -LiteralPath $fp) { [void]$lines.Add(("  {0}  {1} bytes  md5 {2}" -f $f, (Get-Item -LiteralPath $fp).Length, (Md5 $fp))) }
        else { [void]$lines.Add("  $f  (missing)") }
    }
    if (-not ('DadmodRecipes' -as [type])) { Add-Type -Path (Join-Path $Here 'recipes.cs') }
    $why = New-Object System.Collections.ArrayList
    foreach ($r in $recipes) {
        [void]$lines.Add('')
        try {
            $d = [DadmodRecipes]::Diagnose($r, $g)
            [void]$lines.Add($d)
            foreach ($w in (Explain-Problem $d)) { if (-not $why.Contains($w)) { [void]$why.Add($w) } }
        } catch { [void]$lines.Add("couldn't check $r : $($_.Exception.Message)") }
    }
    Say ''
    Say $head
    if ($why.Count -eq 0) { [void]$why.Add("dadmod couldn't work out which file is different (see the report below).") }
    foreach ($w in $why) { Write-Host "  - $w" -ForegroundColor Yellow }
    $name = 'dadmod-install-problem.txt'
    foreach ($dir in @($Pkg, [Environment]::GetFolderPath('Desktop'), $env:TEMP)) {
        if (-not $dir) { continue }
        $out = Join-Path $dir $name
        try {
            [IO.File]::WriteAllLines($out, [string[]]$lines)
            Say ''
            Say "Wrote a report of what didn't match: $out"
            Say 'Please send that file to Noah.'
            return
        } catch { }
    }
}

# map packs (Noah 2026-11-23): the extra levels are separate release assets, so an update only downloads dadmod.zip
function Map-PackLabel($pk) {
    switch ($pk) {
        'cities' { return 'Proving Ground cities by Larxian (Philly, Baltimore, DC)' }
        'p8' { return 'Project 8 maps' }
        'classic' { return 'classic maps (Streets and the THPS2 levels)' }
        'thpg' { return 'THPG Training map' }
    }
    return "$pk maps"
}
function Map-PackShort($pk) {
    switch ($pk) {
        'cities' { return 'city maps' }
        'p8' { return 'Project 8 maps' }
        'classic' { return 'classic maps' }
        'thpg' { return 'THPG map' }
    }
    return "$pk maps"
}

# the download address of a map pack: the asset with that name and size on a published dadmod release
$script:ReleaseList = $null
function Find-PackUrl($info) {
    if (-not $script:ReleaseList) {
        $api = $env:DADMOD_UPDATE_URL
        if (-not $api) { $api = "https://api.github.com/repos/$UpdateRepo/releases?per_page=30" }
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
        try {
            $req = [Net.HttpWebRequest]::Create($api)
            $req.UserAgent = 'dadmod-setup'
            $req.Accept = 'application/vnd.github+json'
            $req.Timeout = 8000
            $req.ReadWriteTimeout = 8000
            $resp = $req.GetResponse()
            $sr = New-Object IO.StreamReader($resp.GetResponseStream())
            $body = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
            $script:ReleaseList = @($body | ConvertFrom-Json)
        } catch { return $null }
    }
    foreach ($rel in @($script:ReleaseList)) {
        if (-not $rel -or $rel.draft) { continue }
        foreach ($a in @($rel.assets)) {
            if ("$($a.name)" -ieq $info.asset -and [long]$a.size -eq $info.size) { return "$($a.browser_download_url)" }
        }
    }
    return $null
}

# -> the stored zip inside a map pack (files/<path in the game folder>), in $tmp; $null when it can't be had
function Get-MapPack($info, $g, $tmp, $from = 0, $to = 0) {
    $label = Map-PackLabel $info.name
    $short = Map-PackShort $info.name
    $mb = [math]::Max(1, [math]::Round($info.size / 1MB))
    $w = $to - $from
    $zip = $null
    # one the player put next to Setup.bat (or in the game's dadmod-install folder)
    foreach ($d in @($Pkg, (Join-Path $g 'dadmod-install'))) {
        if (-not $d) { continue }
        $c = Join-Path $d $info.asset
        if ((Test-Path -LiteralPath $c) -and (Get-Item -LiteralPath $c).Length -eq $info.size -and (Md5-Progress $c $short $from ($from + 0.58 * $w)) -eq $info.md5) {
            Say "Using $($info.asset) from $d."
            $zip = $c; break
        }
    }
    if (-not $zip) {
        $url = Find-PackUrl $info
        if (-not $url) { return $null }
        Say "Downloading the $label ($mb MB)..."
        $zip = Join-Path $tmp $info.asset
        try { Download-Progress $url $zip $short $from ($from + 0.55 * $w) } catch { Say 'The download failed (internet dropped?).'; return $null }
        if ((Get-Item -LiteralPath $zip).Length -ne $info.size -or (Md5-Progress $zip $short ($from + 0.55 * $w) ($from + 0.58 * $w)) -ne $info.md5) { Say 'The download came out wrong.'; return $null }
    }
    Say "Unpacking the $label..."
    Use-Pack2
    $x = Join-Path $tmp ($info.name + '_x')
    try {
        Report ($from + 0.58 * $w) "Extracting ${short}: $mb MB" $true
        [IO.Compression.ZipFile]::ExtractToDirectory($zip, $x)
        $dad = @(Get-ChildItem -LiteralPath $x -Filter '*.dad' -File)
        if ($dad.Count -ne 1) { return $null }
        $inner = Join-Path $tmp ($info.name + '_files.zip')
        Unpack-Progress $dad[0].FullName $inner $short ($from + 0.62 * $w) ($from + 0.96 * $w)
        return $inner
    } catch {
        Say "The $label download is damaged."
        return $null
    } finally {
        Remove-Item -LiteralPath $x -Recurse -Force -ErrorAction SilentlyContinue
        if ($zip -and $zip.StartsWith($tmp)) { Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue }
    }
}

# User\manifest_levels.dat is THUG Pro's list of custom levels (each entry holds the level's name and its .level.dat
# name as NUL-ended strings). When it still lists one of our map-pack levels (installer\vault_levels.txt,
# User\<name>.level.dat rows) whose .level.dat is gone, stock THUG Pro crashes at boot (0x47849B, 2026-11-23).
# Move it to dadmod\backups; THUG Pro writes a new one on its next custom level scan.
function Fix-LevelManifest($g) {
    $man = Join-Path $g 'User\manifest_levels.dat'
    if (-not (Test-Path -LiteralPath $man)) { return }
    $vl = Join-Path $Here 'vault_levels.txt'
    if (-not (Test-Path -LiteralPath $vl)) { return }
    $names = @()
    foreach ($ln in Get-Content -LiteralPath $vl) {
        $m = [regex]::Match("$ln", '^User\\([^\\]+)\.level\.dat\s')
        if ($m.Success) { $names += $m.Groups[1].Value }
    }
    if (-not $names.Count) { return }
    $text = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($man))
    $stale = @()
    foreach ($n in $names) {
        if ($text.IndexOf($n + [char]0, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
            -not (Test-Path -LiteralPath (Join-Path $g "User\$n.level.dat"))) { $stale += $n }
    }
    if (-not $stale.Count) { return }
    $bk = Join-Path $g 'dadmod\backups'
    New-Item -ItemType Directory -Force -Path $bk | Out-Null
    Move-Item -LiteralPath $man -Destination (Join-Path $bk ('manifest_levels.dat.' + (Get-Date).ToString('yyyyMMdd_HHmmss')))
    Say ('Moved User\manifest_levels.dat to dadmod\backups: it still listed removed maps (' + ($stale -join ', ') + '). THUG Pro makes a new one.')
}

function Install($g, [bool]$repair = $false) {
    if (-not (Test-Path -LiteralPath (Join-Path $Files 'binkw32.dll'))) { Fail "the package is missing files\binkw32.dll (unzip the whole package first)" }
    $dadmod = Join-Path $g 'dadmod'
    $log = Join-Path $dadmod 'install.json'
    $state = $null
    if (Test-Path -LiteralPath $log) { $state = Get-Content -LiteralPath $log -Raw | ConvertFrom-Json }
    if ($repair -and -not $state) { Fail "dadmod isn't installed in $g yet (no dadmod\install.json). Pick Install in Setup.bat instead." }
    if ($repair) { Say 'Repair: checking every dadmod file and extra level.' }
    # progress for the updater window (Report: only with DADMOD_PROGRESS=1): checks 0-5, files 5-15, map files 15-20,
    # map packs 20-88 (the slow part when there are any), files built from the game 88-98 (20-98 without packs), done 100
    Report 1 'Checking your game files' $true
    # before anything changes: our script archive has to build from this game's own files
    $qbr = Join-Path (Split-Path -Parent $Here) 'recipes\dadmod_qb.dpr'
    if (Test-Path -LiteralPath $qbr) {
        if (-not ('DadmodRecipes' -as [type])) { Add-Type -Path (Join-Path $Here 'recipes.cs') }
        $tp0 = $null
        if ([DadmodRecipes]::Apply($qbr, $g, [ref]$tp0) -eq $null) {
            Write-Problem $g @($qbr)
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
    # the version this replaces: the game shows "dadmod updated" once (dadmod\update\updated_from.txt, 2026-11-24)
    $oldVer = ''
    $ovf = Join-Path $dadmod 'version.txt'
    if ($state -and (Test-Path -LiteralPath $ovf)) { try { $oldVer = (Get-Content -LiteralPath $ovf -TotalCount 1).Trim() } catch { } }
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
    $vrel = @{}
    $vpack = @{}
    $vl = Join-Path $Here 'vault_levels.txt'
    if (Test-Path -LiteralPath $vl) {
        foreach ($l in Get-Content -LiteralPath $vl) {
            $p = $l.Trim() -split '\s+'
            if ($p[0]) {
                $vault[$p[0].ToLower()] = $(if ($p.Count -gt 1) { $p[1].ToLower() } else { '' })
                $vrel[$p[0].ToLower()] = $p[0]
                $vpack[$p[0].ToLower()] = $(if ($p.Count -gt 2) { $p[2].ToLower() } else { '' })
            }
        }
    }
    # Noah 2026-11-23: the extra levels come in map packs (release assets dadmod-maps-<pack>.zip), listed in
    # installer\map_packs.txt as "<pack> <asset> <size> <md5>"
    $packs = @{}
    $mp = Join-Path $Here 'map_packs.txt'
    if (Test-Path -LiteralPath $mp) {
        foreach ($l in Get-Content -LiteralPath $mp) {
            $p = $l.Trim() -split '\s+'
            if ($p.Count -ge 4) { $packs[$p[0].ToLower()] = @{ name = $p[0].ToLower(); asset = $p[1]; size = [long]$p[2]; md5 = $p[3].ToLower() } }
        }
    }
    $before = @{}
    if ($state) { foreach ($r in @($state.files)) { if ($r) { $before[$r.ToLower()] = $true } } }
    $kept = 0
    $restored = New-Object System.Collections.ArrayList
    $otherVer = New-Object System.Collections.ArrayList
    $dupNames = New-Object System.Collections.ArrayList
    $customToo = New-Object System.Collections.ArrayList
    $all = @(Get-ChildItem -LiteralPath $src -Recurse -File)
    $fi = 0
    Report 5 "Copying files: 0 of $($all.Count)" $true
    foreach ($f in $all) {
        $fi++
        Report (5 + 10 * $fi / [math]::Max(1, $all.Count)) "Copying files: $fi of $($all.Count)"
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
    # the extra levels from the map packs (Noah 2026-11-23): only files that are missing, or ours but an older version,
    # are fetched, from a dadmod-maps-<pack>.zip next to Setup.bat or else downloaded from the dadmod releases. A copy
    # the player already had (not in install.json) stays theirs, untouched and unlisted.
    $need = @{}
    $srcRoot = (Resolve-Path -LiteralPath $Files).Path
    $vkeys = @($vault.Keys | Sort-Object)
    $vi = 0
    Report 15 "Checking map files: 0 of $($vkeys.Count)" $true
    foreach ($low in $vkeys) {
        $vi++
        Report (15 + 5 * $vi / [math]::Max(1, $vkeys.Count)) "Checking map files: $vi of $($vkeys.Count)"
        $rel = $vrel[$low]
        if ($packs.Count -eq 0 -or -not $vpack[$low]) { continue }            # an older package: its loop above did these
        if (Test-Path -LiteralPath (Join-Path $srcRoot $rel)) { continue }     # (same: the file came inside files.dad)
        $dst = Join-Path $g $rel
        $have = Test-Path -LiteralPath $dst
        if ($have -and -not $before[$low]) {
            $kept++
            if ($vault[$low] -and ((Md5 $dst) -ne $vault[$low])) { [void]$otherVer.Add($rel) }
            continue
        }
        if (-not $have -and $rel -match '^user\\([^\\]+)\.level\.dat$' -and -not $before[$low]) {
            $other = Other-LevelDat $g $Matches[1] (Split-Path -Leaf $rel)
            if ($other) { [void]$dupNames.Add("$($Matches[1]) (you have it as User\$other)"); $kept++; continue }
        }
        if ($rel -match '^data\\pre\\(.+)scn\.prx$') {
            if (Test-Path -LiteralPath (Join-Path $g ('User\data\pre\' + (Split-Path -Leaf $rel)))) { [void]$customToo.Add($Matches[1]) }
        }
        if ($have -and (-not $vault[$low] -or (Md5 $dst) -eq $vault[$low])) { [void]$added.Add($rel); continue }
        if (-not $have -and ($before[$low] -or $repair)) { [void]$restored.Add($rel) }
        $pk = $vpack[$low]
        if (-not $need.ContainsKey($pk)) { $need[$pk] = New-Object System.Collections.ArrayList }
        [void]$need[$pk].Add($rel)
    }
    $missingPacks = New-Object System.Collections.ArrayList
    if ($need.Count) {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $mtmp = Join-Path $env:TEMP ('dadmod_maps_' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $mtmp | Out-Null
        try {
            # each pack gets a share of 55-88 by its size
            $pkList = @($need.Keys | Sort-Object)
            $wsum = 0; foreach ($pk in $pkList) { $wsum += $(if ($packs.ContainsKey($pk)) { [double]$packs[$pk].size } else { 1.0 }) }
            $pfrom = 20.0
            foreach ($pk in $pkList) {
                $pw = 68.0 * $(if ($packs.ContainsKey($pk)) { [double]$packs[$pk].size } else { 1.0 }) / [math]::Max(1.0, $wsum)
                $pto = $pfrom + $pw
                $short = Map-PackShort $pk
                $inner = $null
                if ($packs.ContainsKey($pk)) { $inner = Get-MapPack $packs[$pk] $g $mtmp $pfrom $pto }
                $bad = 0
                if ($inner) {
                    $za = [IO.Compression.ZipFile]::OpenRead($inner)
                    try {
                        $ents = @{}
                        foreach ($e in $za.Entries) { $ents[$e.FullName.ToLower()] = $e }
                        $ni = 0; $nn = $need[$pk].Count
                        foreach ($rel in $need[$pk]) {
                            $ni++
                            Report ($pfrom + $pw * (0.96 + 0.04 * $ni / [math]::Max(1, $nn))) "Unpacking ${short}: $ni of $nn files"
                            $e = $ents[('files/' + $rel.Replace('\', '/')).ToLower()]
                            $dst = Join-Path $g $rel
                            if (-not $e) { $bad++; continue }
                            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
                            $tmpf = $dst + '.dadmodnew'
                            [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $tmpf, $true)
                            if ($vault[$rel.ToLower()] -and ((Md5 $tmpf) -ne $vault[$rel.ToLower()])) { Remove-Item -LiteralPath $tmpf -Force; $bad++; continue }
                            Move-Item -LiteralPath $tmpf -Destination $dst -Force
                            if ($rel.ToLower().StartsWith('user\')) { (Get-Item -LiteralPath $dst).LastWriteTime = Get-Date }
                            [void]$added.Add($rel)
                        }
                    } finally { $za.Dispose() }
                    Remove-Item -LiteralPath $inner -Force -ErrorAction SilentlyContinue
                }
                if (-not $inner -or $bad) {
                    [void]$missingPacks.Add($pk)
                    foreach ($rel in $need[$pk]) { [void]$restored.Remove($rel) }
                }
                $pfrom = $pto
            }
        } finally {
            Remove-Item -LiteralPath $mtmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    # files built from the player's own game files (recipes\*.dpr, tools/dadpatch.py): our script archive, the Edit
    # Skater file and the main menu scenes carry no THUG Pro / Kali bytes; each is rebuilt here, byte for byte
    $rdir = Join-Path (Split-Path -Parent $Here) 'recipes'
    if (Test-Path -LiteralPath $rdir) {
        if (-not ('DadmodRecipes' -as [type])) { Add-Type -Path (Join-Path $Here 'recipes.cs') }
        $built = 0
        $failed = New-Object System.Collections.ArrayList
        $failedRecipes = New-Object System.Collections.ArrayList
        $rall = @(Get-ChildItem -LiteralPath $rdir -Filter '*.dpr' -File -Recurse)
        $ri = 0
        # 20-98 unless a map pack was actually fetched (packs with no download address fail at once)
        $bfrom = $(if ($need.Count -gt $missingPacks.Count) { 88 } else { 20 })
        Report $bfrom "Building files from your game: 0 of $($rall.Count)" $true
        foreach ($r in $rall) {
            $ri++
            Report ($bfrom + (98 - $bfrom) * $ri / [math]::Max(1, $rall.Count)) "Building files from your game: $ri of $($rall.Count)"
            $tp = $null
            $bytes = [DadmodRecipes]::Apply($r.FullName, $g, [ref]$tp)
            if ($bytes -eq $null) { [void]$failed.Add($tp); [void]$failedRecipes.Add($r.FullName); continue }
            $dst = Join-Path $g $tp
            if (-not (Test-Path -LiteralPath $dst) -and $before[$tp.ToLower()]) { [void]$restored.Add($tp) }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            [IO.File]::WriteAllBytes($dst, $bytes)
            [void]$added.Add($tp)
            $built++
        }
        if ($failed.Count) {
            # only menu scenes missing (Noah 2026-11-22): dadmod works, those menu backgrounds show the skate shop instead
            $onlyScenes = -not ($failed | Where-Object { $_ -notmatch '^dadmod\\menulevels\\' })
            if ($onlyScenes -and $missingPacks.Count -gt 0) {
                # the menu scenes are built partly from the extra levels' script files (Noah 2026-11-23): with a map
                # pack missing that's expected, not a problem to report
                Say "$($failed.Count) main menu backgrounds use the missing maps, so the menu shows the skate shop in their place until the maps are there (Setup.bat > Repair)."
            } elseif ($onlyScenes) {
                Write-Problem $g @($failedRecipes) 'Why:'
                Say "dadmod is installed and works. $($failed.Count) of the main menu background scenes couldn't be set up from your game files (another mod changed files they use); the menu shows the skate shop in their place:"
            } else {
                Write-Problem $g @($failedRecipes)
                Say "Couldn't build $($failed.Count) files from your game files (your THUG Pro version isn't one dadmod knows):"
            }
            if (-not ($onlyScenes -and $missingPacks.Count -gt 0)) { foreach ($t in $failed) { Say "  $t" } }
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
    Report 100 "Done: $($added.Count) files installed" $true
    $ov = Version-Of $oldVer; $nv = Version-Of $ver
    if (-not $repair -and $ov -and $nv -and $nv -gt $ov) {
        $ud = Join-Path $dadmod 'update'
        New-Item -ItemType Directory -Force -Path $ud | Out-Null
        Set-Content -LiteralPath (Join-Path $ud 'updated_from.txt') -Value $oldVer -Encoding ASCII
    }
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
    if ($missingPacks.Count) {
        Write-Host ''
        foreach ($pk in $missingPacks) {
            $an = $(if ($packs.ContainsKey($pk)) { $packs[$pk].asset } else { "dadmod-maps-$pk.zip" })
            Write-Host ("Couldn't get the " + (Map-PackLabel $pk) + " ($an).") -ForegroundColor Yellow
        }
        Say 'dadmod is installed; those levels are greyed out in level select until their maps are there.'
        Say 'To get them: run Setup.bat > Repair while online, or download the file named above from'
        Say "  https://github.com/$UpdateRepo/releases, put it next to Setup.bat and run Setup.bat > Repair."
    }
    Fix-LevelManifest $g
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
    Fix-LevelManifest $g
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

# the game's updater (main menu > Dadmod > Updates; Noah 2026-11-18, reworked 2026-11-24). The game starts this hidden:
#   -OnQuit: armed as soon as the game has a whole download; waits for every THUG Pro from this folder to close, then
#            installs (Install when I quit) and starts the game again only if the player picked Restart now
#            (the game leaves dadmod\update\restart.txt)
#   without: Restart now when no updater was waiting: waits for the game to close, installs, starts it again
# With -Zip/-Version (the game's own finished download) it installs that file without asking GitHub again.
function Game-Update($g) {
    $upd = Join-Path $g 'dadmod\update'
    New-Item -ItemType Directory -Force -Path $upd | Out-Null
    $script:UpdLog = Join-Path $upd 'update.log'
    # logs stay small (Noah 2026-11-24): update.log keeps its newest half past 200 KB, in place (no .old copy), and the
    # .old logs older versions left behind are removed (update.log.old, soundlog.old.txt)
    try {
        if ((Test-Path -LiteralPath $script:UpdLog) -and (Get-Item -LiteralPath $script:UpdLog).Length -gt 200KB) {
            $all = [System.IO.File]::ReadAllBytes($script:UpdLog)
            $from = [Array]::IndexOf($all, [byte]10, $all.Length - 100KB) + 1
            if ($from -gt 0) { $keep = New-Object byte[] ($all.Length - $from); [Array]::Copy($all, $from, $keep, 0, $keep.Length); [System.IO.File]::WriteAllBytes($script:UpdLog, $keep) }
        }
    } catch { }
    foreach ($old in @(($script:UpdLog + '.old'), (Join-Path $g 'dadmod\soundlog.old.txt'))) {
        try { if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Force } } catch { }
    }
    $restartFile = Join-Path $upd 'restart.txt'
    # one updater per game folder (two open games each start one)
    $id = (Md5Text $g.ToLower()).Substring(0, 12)
    $mtx = New-Object Threading.Mutex($false, "Local\dadmod_updater_$id")
    $mine = $false
    try { $mine = $mtx.WaitOne(0) } catch [Threading.AbandonedMutexException] { $mine = $true }
    if (-not $mine) { Log-Only 'Another dadmod updater is already waiting for this game. This one stops.'; exit 0 }
    Log-Only ("updater started: " + $(if ($OnQuit) { 'install on quit' } else { 'restart now' }) + " (zip: $Zip, version $Version)")
    if ($WaitPid -and -not $OnQuit) {
        try { $gp = Get-Process -Id $WaitPid -ErrorAction Stop; [void]$gp.WaitForExit(60000) } catch { }
    }
    if ($OnQuit) {
        # every THUG Pro from this folder (the -WaitPid game included) must close first. When a player picked Restart
        # now (restart.txt) and another game stays open for a few seconds, the window says why nothing happens yet
        # (two games at once, 2026-11-24)
        $since = $null
        while (Game-Running $g) {
            if (Test-Path -LiteralPath $restartFile) {
                if (-not $since) { $since = Get-Date }
                if (-not $script:UiForm -and ((Get-Date) - $since).TotalSeconds -ge 4) {
                    Show-UpdateWindow 'dadmod updater'
                    Say "dadmod $Version is ready to install."
                    Say 'Waiting for THUG Pro to close: another THUG Pro from this folder is still open. Quit it and the update installs and starts the game again.'
                }
            }
            for ($i = 0; $i -lt 4; $i++) { Start-Sleep -Milliseconds 500; Ui-Pump }
        }
        # the download may be gone (Setup.bat updated meanwhile) or for a version that's already installed
        if (-not ($Zip -and (Test-Path -LiteralPath $Zip))) { Log-Only 'The game''s download is gone. Nothing to do.'; exit 0 }
        $have = Version-Of (Have-Version $g '')
        $want = Version-Of $Version
        if ($have -and $want -and $have -ge $want) { Log-Only "dadmod $Version is already installed. Nothing to do."; exit 0 }
    } else {
        for ($n = 0; (Game-Running $g) -and $n -lt 30; $n++) { Start-Sleep -Seconds 1 }
    }
    $restart = (-not $OnQuit) -or (Test-Path -LiteralPath $restartFile)
    $exe = Join-Path $g 'THUGPro.exe'
    if (-not $script:UiForm) { Show-UpdateWindow 'dadmod updater' }
    if ($Version) { Say "Updating dadmod to $Version..." } else { Say 'Updating dadmod...' }
    if (Game-Running $g) {
        Remove-Item -LiteralPath $restartFile -Force -ErrorAction SilentlyContinue
        Update-Message 'THUG Pro is still open, so nothing was changed. Close it and pick Restart and install in Dadmod > Updates again.' $true
        exit 1
    }
    # the player's dadmod-install folder: the one install.json names, else <game>\dadmod-install
    $script:Pkg = ''
    $state = $null
    try { $state = Get-Content -LiteralPath (Join-Path $g 'dadmod\install.json') -Raw | ConvertFrom-Json } catch { }
    foreach ($c in @($(if ($state) { "$($state.package_dir)" }), (Join-Path $g 'dadmod-install'))) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'Setup.bat'))) { $script:Pkg = $c; break }
    }
    $script:ZipBad = $false
    $u = $null
    if ($Zip -and $Version -and (Test-Path -LiteralPath $Zip)) {
        # the game's finished download: no second GitHub check (a busy GitHub used to throw the download away)
        Report 0 "Checking the download: $(Mb (Get-Item -LiteralPath $Zip).Length) MB" $true
        if ($Sha256 -and ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash -ne $Sha256.ToUpper())) {
            Say 'The download does not match GitHub''s checksum. The game will download it again.'
            $script:ZipBad = $true
        } else {
            $u = @{ state = 'newer'; version = (Version-Of $Version); tag = $Version; url = ''; size = (Get-Item -LiteralPath $Zip).Length; text = '' }
            Report 2 $null $true
        }
    } else {
        Say 'Checking for a newer dadmod...'
        $u = Check-Update (Have-Version $g '')
    }
    $ok = $false
    if ($u) {
        if ($u.text) { Say $u.text }
        if ($u.state -eq 'newer') { $ok = Get-Update $u $g $Zip }
    }
    if ($ok -or $script:ZipBad) {
        # used up (or damaged): the game downloads again when it needs to
        foreach ($f in @($Zip, "$Zip.ver")) { if ($f -and (Test-Path -LiteralPath $f)) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue } }
    }
    Remove-Item -LiteralPath $restartFile -Force -ErrorAction SilentlyContinue
    if ($ok) {
        Set-Progress 100
        Say "dadmod $($u.tag) is installed."
        if ($restart) { Say 'Starting THUG Pro...' }
        Ui-Pump
        Start-Sleep -Seconds 2
        Close-UpdateWindow
    } elseif ($u -and $u.state -ne 'newer') {
        Close-UpdateWindow
    } else {
        $why = $(if ($script:UiLines.Count) { $script:UiLines[-1] } else { '' })
        Update-Message ("The update did not finish, so your dadmod is as it was.`r`n`r`n$why`r`n`r`nIf it keeps happening, run Setup.bat in your dadmod-install folder. Details: dadmod\update\update.log") $true
    }
    if ($restart) {
        Start-Process -FilePath $exe -WorkingDirectory $g
        Start-Sleep -Seconds 2
    }
    try { $mtx.ReleaseMutex() } catch { }
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
