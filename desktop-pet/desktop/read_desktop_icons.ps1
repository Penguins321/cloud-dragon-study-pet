param(
    [Parameter(Mandatory = $true)][string]$SnapshotPath,
    [int]$ParentProcessId = 0,
    [switch]$Once
)

# Read-only Explorer geometry. Never request names, patterns, or file contents.
# UIA screen bounds are physical pixels; native pointer/hit testing uses the same DPI context.
# https://learn.microsoft.com/dotnet/api/system.windows.automation.automationelement.fromhandle
# https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-setthreaddpiawarenesscontext
# https://learn.microsoft.com/windows/win32/api/oleacc/nf-oleacc-accessiblechildren
# https://learn.microsoft.com/windows/win32/api/oleacc/nf-oleacc-iaccessible-acclocation
$ErrorActionPreference = 'Stop'
if (-not $Once -and $ParentProcessId -le 0) { exit 2 }
$SnapshotPath = [IO.Path]::GetFullPath($SnapshotPath)
$temporaryPath = $SnapshotPath + '.' + $PID + '.tmp'
$encoding = New-Object Text.UTF8Encoding($false)
$ready = $false
try {
    Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, WindowsBase, Accessibility
    Add-Type -ReferencedAssemblies ([Accessibility.IAccessible].Assembly.Location) -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class PetDesktopNative {
    public delegate bool EnumWindowProc(IntPtr window, IntPtr parameter);
    [StructLayout(LayoutKind.Sequential)] public struct Point { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowProc callback, IntPtr parameter);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr window, StringBuilder name, int maximum);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out Point point);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(Point point);
    [DllImport("user32.dll")] public static extern bool IsChild(IntPtr parent, IntPtr child);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll", SetLastError=true)] static extern IntPtr SendMessageTimeout(IntPtr window, uint message, UIntPtr wp, IntPtr lp, uint flags, uint timeout, out UIntPtr result);
    [DllImport("oleacc.dll")] public static extern int AccessibleObjectFromWindow(IntPtr window, uint objectId, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out Accessibility.IAccessible accessible);
    [DllImport("oleacc.dll")] public static extern int AccessibleChildren([MarshalAs(UnmanagedType.Interface)] object accessible, int start, int count, [Out, MarshalAs(UnmanagedType.LPArray, ArraySubType=UnmanagedType.Struct, SizeParamIndex=2)] object[] children, out int obtained);
    public static int[][] AccessibleBounds(IntPtr list) {
        var rectangles = new System.Collections.Generic.List<int[]>();
        Guid iid = new Guid("618736e0-3c3d-11cf-810c-00aa00389b71");
        Accessibility.IAccessible accessible;
        if (AccessibleObjectFromWindow(list, 0xFFFFFFFC, ref iid, out accessible) != 0 || accessible == null) return rectangles.ToArray();
        try {
            int count = Math.Min(512, Math.Max(0, accessible.accChildCount));
            object[] children = new object[count]; int obtained;
            if (count == 0 || AccessibleChildren(accessible, 0, count, children, out obtained) < 0) return rectangles.ToArray();
            for (int i = 0; i < Math.Min(obtained, 512); i++) {
                var owner = accessible; object childId = children[i];
                if (!(childId is int)) { owner = childId as Accessibility.IAccessible; childId = 0; }
                if (owner == null || !Object.Equals(owner.get_accRole(childId), 34)) continue;
                int x, y, width, height; owner.accLocation(out x, out y, out width, out height, childId);
                if (Math.Abs((long)x) <= 1000000 && Math.Abs((long)y) <= 1000000 && width > 0 && height > 0 && width <= 4096 && height <= 4096) rectangles.Add(new int[] { x, y, width, height });
            }
        } finally { Marshal.ReleaseComObject(accessible); }
        return rectangles.ToArray();
    }
    public static long IconCount(IntPtr list) {
        // LVM_GETITEMCOUNT has no pointer payload or remote-process memory access.
        UIntPtr count;
        return SendMessageTimeout(list, 0x1004, UIntPtr.Zero, IntPtr.Zero, 2, 500, out count) == IntPtr.Zero ? -1 : (long)count.ToUInt64();
    }
    public static IntPtr DesktopList() {
        IntPtr result = IntPtr.Zero;
        EnumWindows(delegate(IntPtr top, IntPtr unused) {
            var name = new StringBuilder(64); GetClassName(top, name, name.Capacity);
            if (name.ToString() != "Progman" && name.ToString() != "WorkerW") return true;
            var view = FindWindowEx(top, IntPtr.Zero, "SHELLDLL_DefView", null);
            if (view == IntPtr.Zero) return true;
            var list = FindWindowEx(view, IntPtr.Zero, "SysListView32", null);
            if (list == IntPtr.Zero || !IsWindowVisible(list)) return true;
            result = list; return false;
        }, IntPtr.Zero);
        return result;
    }
}
'@
    $ready = $true
} catch { }

$sequence = 0
try {
    do {
        if (-not $Once) {
            try { $parent = Get-Process -Id $ParentProcessId -ErrorAction Stop }
            catch { break }
        }
        $sequence++
        $snapshot = [ordered]@{ sequence = $sequence; available = $false; icons = @(); desktop_under_pointer = $false; pointer = @(0, 0); left_button_down = $false }
        if ($ready) {
            $oldDpi = [IntPtr]::Zero
            try {
                $oldDpi = [PetDesktopNative]::SetThreadDpiAwarenessContext([IntPtr](-4))
                if ($oldDpi -eq [IntPtr]::Zero) { throw 'DPI context unavailable' }
                $point = New-Object PetDesktopNative+Point
                if (-not [PetDesktopNative]::GetCursorPos([ref]$point)) { throw 'Pointer unavailable' }
                $snapshot.pointer = @($point.X, $point.Y)
                $snapshot.left_button_down = (([int][PetDesktopNative]::GetAsyncKeyState(1) -band 32768) -ne 0)
                $list = [PetDesktopNative]::DesktopList()
                if ($list -eq [IntPtr]::Zero) { throw 'Explorer unavailable' }
                $bounds = New-Object 'System.Collections.Generic.List[object]'
                try {
                $element = [Windows.Automation.AutomationElement]::FromHandle($list)
                $walker = [Windows.Automation.TreeWalker]::ControlViewWalker
                $child = $walker.GetFirstChild($element)
                # Stop at the cap, even if Explorer reports more children.
                for ($index = 0; $null -ne $child -and $index -lt 512; $index++) {
                    if ($child.GetCurrentPropertyValue([Windows.Automation.AutomationElement]::ControlTypeProperty) -eq [Windows.Automation.ControlType]::ListItem) {
                        $rect = $child.GetCurrentPropertyValue([Windows.Automation.AutomationElement]::BoundingRectangleProperty)
                        $values = @($rect.X, $rect.Y, $rect.Width, $rect.Height)
                        $valid = $true
                        foreach ($value in $values) {
                            if ([double]::IsNaN($value) -or [double]::IsInfinity($value) -or [Math]::Abs($value) -gt 1000000) { $valid = $false }
                        }
                        if ($valid -and $rect.Width -gt 0 -and $rect.Height -gt 0 -and $rect.Width -le 4096 -and $rect.Height -le 4096) {
                            $bounds.Add(@([int][Math]::Floor($rect.X), [int][Math]::Floor($rect.Y), [int][Math]::Ceiling($rect.Width), [int][Math]::Ceiling($rect.Height)))
                        }
                    }
                    if ($index -lt 511) { $child = $walker.GetNextSibling($child) }
                }
                } catch { $bounds.Clear() }
                # Explorer can omit UIA children. Its documented MSAA provider exposes
                # the same screen rectangles without requesting text or taking actions.
                if ($bounds.Count -eq 0) {
                    foreach ($rectangle in [PetDesktopNative]::AccessibleBounds($list)) { $bounds.Add($rectangle) }
                }
                # Only accept empty geometry if the native list confirms zero icons.
                if ($bounds.Count -eq 0 -and [PetDesktopNative]::IconCount($list) -ne 0) { throw 'Icon geometry unavailable' }
                $hit = [PetDesktopNative]::WindowFromPoint($point)
                $snapshot.desktop_under_pointer = ($hit -eq $list -or [PetDesktopNative]::IsChild($list, $hit))
                $snapshot.icons = @($bounds.ToArray())
                $snapshot.available = $true
            } catch {
                $snapshot.available = $false
                $snapshot.icons = @()
                $snapshot.desktop_under_pointer = $false
            } finally {
                if ($oldDpi -ne [IntPtr]::Zero) { [void][PetDesktopNative]::SetThreadDpiAwarenessContext($oldDpi) }
            }
        }
        try {
            $json = ConvertTo-Json -InputObject $snapshot -Depth 4 -Compress
            [IO.File]::WriteAllText($temporaryPath, $json, $encoding)
            if ([IO.File]::Exists($SnapshotPath)) { [IO.File]::Replace($temporaryPath, $SnapshotPath, [Management.Automation.Language.NullString]::Value) }
            else { [IO.File]::Move($temporaryPath, $SnapshotPath) }
        } catch { break }
        if (-not $Once) { Start-Sleep -Milliseconds 1000 }
    } while (-not $Once)
} finally {
    if ([IO.File]::Exists($temporaryPath)) { [IO.File]::Delete($temporaryPath) }
}
