# Compiles every shader in gfx.inc's kShaders with d3dx9_43 (same compiler the DLL uses) and prints how many
# instruction slots each one takes. NVIDIA's D3D9 driver rejects ps_3_0 shaders over about 4096 slots
# (2026-11-21: ps_sky at ~4022 made a player's galaxy sky crash), so anything near that is flagged.
# Must run in 32-bit PowerShell (d3dx9_43 is 32-bit):
#   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File shaderslots.ps1 [-Inc gfx.inc] [-Limit 3500]
param([string]$Inc = (Join-Path $PSScriptRoot 'gfx.inc'), [int]$Limit = 3500, [string]$Names = '')
# -Names a,b,c checks only those pixel shaders (framegen.inc: -Inc framegen.inc -Limit 512 -Names ps_fg_copy,...)
$ErrorActionPreference = 'Stop'
if ([IntPtr]::Size -ne 4) { Write-Host 'shaderslots: needs 32-bit PowerShell (SysWOW64)'; exit 2 }
$src = [IO.File]::ReadAllText($Inc)
$a = $src.IndexOf('R"HLSL('); $b = $src.IndexOf(')HLSL"')
if ($a -lt 0 -or $b -lt $a) { Write-Host 'shaderslots: no kShaders block found'; exit 2 }
$hlsl = $src.Substring($a + 7, $b - $a - 7)
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class DxSlots {
  [DllImport("d3dx9_43.dll", CharSet = CharSet.Ansi)] static extern int D3DXCompileShader(string src, uint len, IntPtr defs, IntPtr inc, string fn, string prof, uint flags, out IntPtr code, out IntPtr err, IntPtr table);
  [DllImport("d3dx9_43.dll")] static extern int D3DXDisassembleShader(IntPtr code, bool color, string comments, out IntPtr buf);
  [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate IntPtr GetP(IntPtr self);
  [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate uint Rel(IntPtr self);
  static string Text(IntPtr b) {
    IntPtr vt = Marshal.ReadIntPtr(b);
    var p = (GetP)Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(vt, 12), typeof(GetP));
    return Marshal.PtrToStringAnsi(p(b));
  }
  static void Free(IntPtr b) { if (b == IntPtr.Zero) return; IntPtr vt = Marshal.ReadIntPtr(b); ((Rel)Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(vt, 8), typeof(Rel)))(b); }
  public static string Run(string src, string fn, string prof) {
    IntPtr code, err;
    int hr = D3DXCompileShader(src, (uint)src.Length, IntPtr.Zero, IntPtr.Zero, fn, prof, 0, out code, out err, IntPtr.Zero);
    if (hr < 0 || code == IntPtr.Zero) { string e = err != IntPtr.Zero ? Text(err) : "?"; Free(err); Free(code); return "ERROR " + e; }
    Free(err);
    IntPtr dis; IntPtr p = ((GetP)Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(Marshal.ReadIntPtr(code), 12), typeof(GetP)))(code);
    hr = D3DXDisassembleShader(p, false, null, out dis);
    Free(code);
    if (hr < 0) return "ERROR disassemble";
    string t = Text(dis); Free(dis); return t;
  }
}
'@
$list = @(,@('vs_main','vs_3_0')) +(@('ps_fxaa','ps_bright','ps_down','ps_blur','ps_scene','ps_look','ps_screen','ps_galaxy','ps_ao','ps_aoblur','ps_sky','ps_sky5','ps_sky6','ps_sky7','ps_sky8','ps_sky9','ps_sky10','ps_sky11','ps_sky12','ps_sky13','ps_sky14','ps_weather','ps_fireworks','ps_lamps','ps_bulbs','ps_nighttint','ps_wincomp','ps_bhalo','ps_bpool','ps_moon','ps_winvis','ps_lampcur','ps_lampprobe','ps_btile','ps_mirror') | ForEach-Object { ,@($_, 'ps_3_0') }) + @(,@('ps_window','ps_2_0'))
if ($Names) { $list = @($Names.Split(',') | ForEach-Object { ,@($_.Trim(), 'ps_3_0') }) }
$bad = 0
foreach ($s in $list) {
  $t = [DxSlots]::Run($hlsl, $s[0], $s[1])
  if ($t.StartsWith('ERROR')) { Write-Host ("shader {0,-13} {1}" -f $s[0], $t); $bad++; continue }
  $m = [regex]::Match($t, 'approximately (\d+) instruction slots? used')
  $n = if ($m.Success) { [int]$m.Groups[1].Value } else { -1 }
  $flag = if ($n -gt $Limit) { "  <-- OVER $Limit (NVIDIA rejects about 4096+)" } else { '' }
  if ($n -gt $Limit) { $bad++ }
  Write-Host ("shader {0,-13} {1,5} slots{2}" -f $s[0], $n, $flag)
}
exit $bad
