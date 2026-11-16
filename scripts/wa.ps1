# WA delta: drives WhatsApp Desktop. Text arguments are base64 UTF-8.
#   wa.ps1 open  <b64 name>                      open chat via search (marks it seen)
#   wa.ps1 type  <b64 text> <minMs> <maxMs>      type char by char ("typing..." shows), Enter
#   wa.ps1 paste <b64 text>                      paste at once, Enter (clipboard restored)
#   wa.ps1 hide                                  minimize so new messages raise toasts
param([string]$Action, [string]$Arg, [int]$MinMs = 110, [int]$MaxMs = 220)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System; using System.Threading; using System.Runtime.InteropServices;
public class WD {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(int f, int x, int y, int d, int e);
 [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] i, int size);
 public struct RECT { public int L, T, R, B; }
 [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
 [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort vk, scan; public uint flags, time; public IntPtr extra; }
 [StructLayout(LayoutKind.Explicit)] struct U { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
 [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public U u; }
 static INPUT K(ushort vk, ushort scan, uint flags) { var i = new INPUT(); i.type = 1; i.u.ki.vk = vk; i.u.ki.scan = scan; i.u.ki.flags = flags; return i; }
 static void Send(params INPUT[] a) { SendInput((uint)a.Length, a, Marshal.SizeOf(typeof(INPUT))); }
 public static void Vk(ushort vk) { Send(K(vk, 0, 0), K(vk, 0, 2)); }
 public static void Chord(ushort mod, ushort vk) { Send(K(mod, 0, 0), K(vk, 0, 0), K(vk, 0, 2), K(mod, 0, 2)); }
 public static void Type(string s, int minMs, int maxMs) {
  var r = new Random();
  for (int i = 0; i < s.Length; i++) {
   char c = s[i];
   if (c == '\r') continue;
   if (c == '\n') { Chord(0x10, 0x0D); }
   else if (char.IsHighSurrogate(c) && i + 1 < s.Length) {
    char d = s[++i];
    Send(K(0, c, 4), K(0, d, 4), K(0, c, 6), K(0, d, 6));
   } else { Send(K(0, c, 4), K(0, c, 6)); }
   int w = r.Next(minMs, maxMs + 1);
   if (c == ' ' && r.NextDouble() < 0.15) w *= 2;
   if (".,!?".IndexOf(c) >= 0) w *= 3;
   Thread.Sleep(w);
  }
 }
}
'@
[WD]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Windows.Forms

$p = Get-Process WhatsApp* -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { Write-Output 'ERR WhatsApp window not found'; exit 2 }
$h = $p.MainWindowHandle
$text = if ($Arg) { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Arg)) } else { '' }

function Front { [WD]::ShowWindow($h, 3) | Out-Null; [WD]::SetForegroundWindow($h) | Out-Null; Start-Sleep -Milliseconds 700 }
# offsets measured at 96 dpi from the maximized window's top-left (bottom for the composer)
function At([int]$x, [int]$y, [switch]$FromBottom) {
  $r = New-Object WD+RECT; [WD]::GetWindowRect($h, [ref]$r) | Out-Null
  $k = [WD]::GetDpiForWindow($h) / 96.0
  $py = if ($FromBottom) { $r.B - [int]($y * $k) } else { $r.T + [int]($y * $k) }
  [WD]::SetCursorPos($r.L + [int]($x * $k), $py) | Out-Null
  [WD]::mouse_event(2,0,0,0,0); [WD]::mouse_event(4,0,0,0,0)
}

switch ($Action) {
 'open' {
  Front
  At 264 118; Start-Sleep -Milliseconds 300          # search box
  [WD]::Chord(0x11, 0x41); [WD]::Type($text, 15, 35)  # ctrl+a, name
  Start-Sleep -Milliseconds 1300
  At 240 256; Start-Sleep -Milliseconds 800           # first result under "Chats"
  At 387 118; Start-Sleep -Milliseconds 300           # clear the search
  Write-Output 'OK opened'
 }
 'type' {
  Front; At 456 77 -FromBottom; Start-Sleep -Milliseconds 300
  [WD]::Type($text, $MinMs, $MaxMs); Start-Sleep -Milliseconds 400
  [WD]::Vk(0x0D); Start-Sleep -Milliseconds 700
  Write-Output 'OK sent'
 }
 'paste' {
  Front; At 456 77 -FromBottom; Start-Sleep -Milliseconds 300
  $old = $null; try { $old = Get-Clipboard -Raw } catch {}
  Set-Clipboard -Value $text; [WD]::Chord(0x11, 0x56); Start-Sleep -Milliseconds 400
  [WD]::Vk(0x0D); Start-Sleep -Milliseconds 700
  if ($old) { Set-Clipboard -Value $old }
  Write-Output 'OK sent'
 }
 'hide' { [WD]::ShowWindow($h, 6) | Out-Null; Write-Output 'OK hidden' }
 default { Write-Output 'ERR actions: open | type | paste | hide'; exit 1 }
}
