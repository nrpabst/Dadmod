// dadmod recipe applier (tools/dadpatch.py makes the recipes). Loaded by installer\dadmod.ps1 with Add-Type, so it runs
// with plain Windows PowerShell. Rebuilds one of our files from the player's own game files plus our own bytes.
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class DadmodRecipes {
    static Dictionary<string, Dictionary<string, byte[]>> prxCache = new Dictionary<string, Dictionary<string, byte[]>>();
    static Dictionary<string, byte[]> fileCache = new Dictionary<string, byte[]>();

    // PRE v3 entry unpacker (Okumura LZSS, ring starts as spaces), same as tools/prx_extract.py
    static byte[] Lzss(byte[] src, int outSize) {
        const int N = 4096, F = 18, TH = 2;
        byte[] ring = new byte[N];
        for (int k = 0; k < N; k++) ring[k] = 0x20;
        int r = N - F, i = 0, flags = 0, o = 0;
        byte[] outb = new byte[outSize];
        while (o < outSize && i < src.Length) {
            flags >>= 1;
            if ((flags & 0x100) == 0) { flags = src[i++] | 0xFF00; }
            if ((flags & 1) != 0) {
                if (i >= src.Length) break;
                byte c = src[i++];
                outb[o++] = c; ring[r] = c; r = (r + 1) & (N - 1);
            } else {
                if (i + 1 >= src.Length) break;
                int lo = src[i], hi = src[i + 1]; i += 2;
                int pos = lo | ((hi & 0xF0) << 4), ln = (hi & 0x0F) + TH + 1;
                for (int k = 0; k < ln && o < outSize; k++) {
                    byte c = ring[(pos + k) & (N - 1)];
                    outb[o++] = c; ring[r] = c; r = (r + 1) & (N - 1);
                }
            }
        }
        return outb;
    }

    static Dictionary<string, byte[]> ReadPrx(string path) {
        string key = path.ToLowerInvariant();
        Dictionary<string, byte[]> d;
        if (prxCache.TryGetValue(key, out d)) return d;
        d = new Dictionary<string, byte[]>(StringComparer.OrdinalIgnoreCase);
        byte[] b = File.ReadAllBytes(path);
        int n = BitConverter.ToInt32(b, 8), off = 12;
        for (int e = 0; e < n; e++) {
            int usz = BitConverter.ToInt32(b, off), csz = BitConverter.ToInt32(b, off + 4), nl = BitConverter.ToInt32(b, off + 8);
            off += 16;
            int z = 0; while (z < nl && b[off + z] != 0) z++;
            string name = Encoding.GetEncoding(28591).GetString(b, off, z);
            off += nl;
            int dl = csz != 0 ? csz : usz;
            byte[] raw = new byte[dl]; Buffer.BlockCopy(b, off, raw, 0, dl);
            off += (dl + 3) & ~3;
            d[name] = csz != 0 ? Lzss(raw, usz) : raw;
        }
        prxCache[key] = d;
        return d;
    }

    // "thug2:" sources live in the THUG2 game folder THUG Pro reads THUG2 levels from
    static string Thug2Root() {
        try {
            using (var k = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\THUG Pro\Settings")) {
                return k == null ? null : k.GetValue("thug2_path") as string;
            }
        } catch { return null; }
    }

    static byte[] Source(string game, string path, string entry) {
        string full;
        if (path.StartsWith("thug2:", StringComparison.OrdinalIgnoreCase)) {
            string root = Thug2Root();
            if (string.IsNullOrEmpty(root)) return null;
            full = Path.Combine(root, path.Substring(6));
        } else full = Path.Combine(game, path);
        if (!File.Exists(full)) return null;
        if (entry.Length == 0) {
            string k = full.ToLowerInvariant();
            byte[] f;
            if (!fileCache.TryGetValue(k, out f)) { f = File.ReadAllBytes(full); fileCache[k] = f; }
            return f;
        }
        byte[] data;
        return ReadPrx(full).TryGetValue(entry, out data) ? data : null;
    }

    static bool Same(byte[] a, byte[] b) {
        if (a.Length != b.Length) return false;
        for (int k = 0; k < a.Length; k++) if (a[k] != b[k]) return false;
        return true;
    }

    // returns the rebuilt file (null when no variant matches this game), and the game-relative path it belongs at
    public static byte[] Apply(string recipe, string game, out string targetPath) {
        byte[] b = File.ReadAllBytes(recipe);
        if (b[0] != 'D' || b[1] != 'P' || b[2] != 'R' || b[3] != '1') throw new Exception("not a dadmod recipe: " + recipe);
        int size = BitConverter.ToInt32(b, 4);
        byte[] md5 = new byte[16]; Buffer.BlockCopy(b, 8, md5, 0, 16);
        int p = 24;
        Func<string> S = () => { int ln = BitConverter.ToUInt16(b, p); p += 2; string v = Encoding.UTF8.GetString(b, p, ln); p += ln; return v; };
        targetPath = S();
        int nv = BitConverter.ToUInt16(b, p); p += 2;
        MD5 hasher = MD5.Create();
        for (int v = 0; v < nv; v++) {
            int ns = BitConverter.ToUInt16(b, p); p += 2;
            byte[][] datas = new byte[ns][];
            bool ok = true;
            for (int s = 0; s < ns; s++) {
                string path = S(), entry = S();
                byte[] m = new byte[16]; Buffer.BlockCopy(b, p, m, 0, 16); p += 16;
                if (!ok) continue;
                byte[] d = Source(game, path, entry);
                if (d == null || !Same(hasher.ComputeHash(d), m)) { ok = false; continue; }
                datas[s] = d;
            }
            int no = BitConverter.ToInt32(b, p); p += 4;
            MemoryStream outs = ok ? new MemoryStream(size) : null;
            for (int o = 0; o < no; o++) {
                byte t = b[p];
                if (t == 1) {
                    int si = BitConverter.ToUInt16(b, p + 1), so = BitConverter.ToInt32(b, p + 3), ln = BitConverter.ToInt32(b, p + 7);
                    p += 11;
                    if (outs != null) outs.Write(datas[si], so, ln);
                } else {
                    int ln = BitConverter.ToInt32(b, p + 1);
                    if (outs != null) outs.Write(b, p + 5, ln);
                    p += 5 + ln;
                }
            }
            if (outs != null) {
                byte[] res = outs.ToArray();
                if (res.Length == size && Same(hasher.ComputeHash(res), md5)) return res;
            }
        }
        return null;
    }
}
