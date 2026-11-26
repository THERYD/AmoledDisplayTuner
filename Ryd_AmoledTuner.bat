<# : AMOLED Display Tuner v3 - launcher (the PowerShell app is below)
@echo off
set "AMO_SELF=%~f0"
set "AMO_ARGS=%*"
if /i "%~1"=="debug" (
  powershell -NoProfile -STA -ExecutionPolicy Bypass -NoExit -Command "iex ([IO.File]::ReadAllText($env:AMO_SELF))"
) else (
  start "" powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -Command "iex ([IO.File]::ReadAllText($env:AMO_SELF))"
)
exit /b
#>

# =====================================================================
#  AMOLED DISPLAY TUNER  v3.0
#  Copyright (c) 2026 Md. Tanvir Islam Riyad (10vir.me). All rights reserved.
#
#  LICENSE - PROPRIETARY
#  This software and its source code are the property of Md. Tanvir Islam
#  Riyad. You may download and use it for personal use, free of charge.
#  Without written permission from the author you may NOT:
#    - modify, rebrand or re-publish it under another name or creator,
#    - remove or change the creator credits, About page or this notice,
#    - sell, rent or redistribute it, in original or modified form.
#  Contact: https://www.instagram.com/svg_riyaaad/  |  http://10vir.me/
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
# =====================================================================

try {

# ---------- CREATOR ----------
$AppName    = 'AMOLED Display Tuner'
$AppVersion = '3.0'
$Creator = [ordered]@{
    Name      = 'Md. Tanvir Islam Riyad'
    Short     = 'Riyad (RYD)'
    Role      = 'Frontend Developer  |  Creative Coder  |  IT Student'
    Location  = 'Cyberjaya, Malaysia'
    Bio       = 'IT student and aspiring software developer, passionate about building modern, interactive and user-friendly apps.'
    Website   = 'http://10vir.me/'
    Instagram = 'https://www.instagram.com/svg_riyaaad/'
    LinkedIn  = 'https://www.linkedin.com/in/riyad200'
    Photo     = 'https://10vir.me/img/IMG_2125.JPG'
}
$Copyright = ([string][char]0xA9) + " 2026 $($Creator.Name). All rights reserved."
$LicenseText = "Proprietary software. Free for personal use. You may not modify, rebrand, resell or redistribute this app, " +
               "or remove the creator credits, without written permission from $($Creator.Name)."
# Opened in the browser each time the app is opened by hand (not when it starts with Windows).
$OpenOnLaunch = @( $Creator.Website, $Creator.Instagram, $Creator.LinkedIn )
function Open-Url($u) { try { Start-Process $u } catch {} }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$cs = @"
using System;
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class AmoNative {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr h, int attr, ref int val, int size);
    public static void StyleWindow(IntPtr h) {
        int one = 1, round = 2;
        int cap = AmoTheme.Bg.R | (AmoTheme.Bg.G << 8) | (AmoTheme.Bg.B << 16);
        int txt = AmoTheme.Text.R | (AmoTheme.Text.G << 8) | (AmoTheme.Text.B << 16);
        try { DwmSetWindowAttribute(h, 20, ref one, 4); DwmSetWindowAttribute(h, 19, ref one, 4); } catch { }
        try { DwmSetWindowAttribute(h, 33, ref round, 4); } catch { }
        try { DwmSetWindowAttribute(h, 35, ref cap, 4); DwmSetWindowAttribute(h, 36, ref txt, 4); } catch { }
    }

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, EntryPoint = "CreateDCW")]
    static extern IntPtr CreateDC(string drv, string dev, string output, IntPtr init);
    [DllImport("gdi32.dll")] static extern bool DeleteDC(IntPtr hdc);
    [DllImport("gdi32.dll")] static extern bool SetDeviceGammaRamp(IntPtr hdc, ushort[] ramp);
    public static bool ApplyRamp(string dev, ushort[] ramp) {
        IntPtr h = CreateDC(dev, null, null, IntPtr.Zero);
        if (h == IntPtr.Zero) return false;
        try { return SetDeviceGammaRamp(h, ramp); } finally { DeleteDC(h); }
    }

    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct PHYSICAL_MONITOR {
        public IntPtr hPhysicalMonitor;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string szDesc;
    }
    [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(POINT pt, uint flags);
    [DllImport("dxva2.dll")] static extern bool GetNumberOfPhysicalMonitorsFromHMONITOR(IntPtr hm, out uint n);
    [DllImport("dxva2.dll")] static extern bool GetPhysicalMonitorsFromHMONITOR(IntPtr hm, uint n, [Out] PHYSICAL_MONITOR[] arr);
    [DllImport("dxva2.dll")] static extern bool DestroyPhysicalMonitors(uint n, PHYSICAL_MONITOR[] arr);
    [DllImport("dxva2.dll")] static extern bool GetMonitorBrightness(IntPtr h, out uint mn, out uint cur, out uint mx);
    [DllImport("dxva2.dll")] static extern bool SetMonitorBrightness(IntPtr h, uint v);
    [DllImport("dxva2.dll")] static extern bool GetMonitorContrast(IntPtr h, out uint mn, out uint cur, out uint mx);
    [DllImport("dxva2.dll")] static extern bool SetMonitorContrast(IntPtr h, uint v);
    static PHYSICAL_MONITOR[] Open(int x, int y) {
        POINT p; p.X = x; p.Y = y;
        IntPtr hm = MonitorFromPoint(p, 2);
        uint n;
        if (!GetNumberOfPhysicalMonitorsFromHMONITOR(hm, out n) || n == 0) return null;
        PHYSICAL_MONITOR[] arr = new PHYSICAL_MONITOR[n];
        if (!GetPhysicalMonitorsFromHMONITOR(hm, n, arr)) return null;
        return arr;
    }
    public static int[] GetVcp(int x, int y, int kind) {
        PHYSICAL_MONITOR[] arr = Open(x, y);
        if (arr == null) return null;
        try {
            uint a, b, c;
            bool ok = kind == 0 ? GetMonitorBrightness(arr[0].hPhysicalMonitor, out a, out b, out c)
                                : GetMonitorContrast(arr[0].hPhysicalMonitor, out a, out b, out c);
            if (!ok) return null;
            return new int[] { (int)a, (int)b, (int)c };
        } finally { DestroyPhysicalMonitors((uint)arr.Length, arr); }
    }
    public static bool SetVcp(int x, int y, int kind, int v) {
        PHYSICAL_MONITOR[] arr = Open(x, y);
        if (arr == null) return false;
        bool ok = true;
        try {
            for (int i = 0; i < arr.Length; i++) {
                bool r = kind == 0 ? SetMonitorBrightness(arr[i].hPhysicalMonitor, (uint)v)
                                   : SetMonitorContrast(arr[i].hPhysicalMonitor, (uint)v);
                if (!r) ok = false;
            }
        } finally { DestroyPhysicalMonitors((uint)arr.Length, arr); }
        return ok;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }
    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "EnumDisplayDevicesW")]
    static extern bool EnumDisplayDevices(string dev, uint i, ref DISPLAY_DEVICE dd, uint flags);
    public static string[] MonitorInfo(string adapter) {
        string desc = null, id = null;
        DISPLAY_DEVICE d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
        if (EnumDisplayDevices(adapter, 0, ref d, 0)) desc = d.DeviceString;
        d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
        if (EnumDisplayDevices(adapter, 0, ref d, 1)) id = d.DeviceID;
        return new string[] { desc, id };
    }
}

public class HotkeyArgs : EventArgs { public int Id; }
public class AmoHotkeys : NativeWindow, IDisposable {
    [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr h, int id, uint mod, uint vk);
    [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr h, int id);
    public event EventHandler<HotkeyArgs> Pressed;
    public AmoHotkeys() { CreateHandle(new CreateParams()); }
    public bool Register(int id, uint mod, uint vk) { return RegisterHotKey(Handle, id, mod, vk); }
    protected override void WndProc(ref Message m) {
        if (m.Msg == 0x0312 && Pressed != null) { HotkeyArgs a = new HotkeyArgs(); a.Id = m.WParam.ToInt32(); Pressed(this, a); }
        base.WndProc(ref m);
    }
    public void Dispose() { for (int i = 1; i <= 10; i++) UnregisterHotKey(Handle, i); DestroyHandle(); }
}
public class OsdForm : Form {
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get { CreateParams cp = base.CreateParams; cp.ExStyle |= 0x08000000 | 0x00000080 | 0x00000008; return cp; }
    }
}

// ======================= UI KIT =======================
public static class AmoTheme {
    // Green gradient theme: deep emerald -> fresh lime
    public static Color Bg = Color.FromArgb(8, 11, 9);
    public static Color Card = Color.FromArgb(15, 20, 17);
    public static Color Card2 = Color.FromArgb(23, 30, 26);
    public static Color Border = Color.FromArgb(38, 52, 44);
    public static Color Hover = Color.FromArgb(30, 50, 38);
    public static Color Text = Color.FromArgb(230, 240, 233);
    public static Color Dim = Color.FromArgb(136, 156, 144);
    public static Color Accent = Color.FromArgb(18, 200, 110);
    public static Color AccentDark = Color.FromArgb(12, 62, 36);
    public static Color Cyan = Color.FromArgb(170, 240, 60);
    public static float Scale = 1f;
    public static int S(float v) { return (int)Math.Round(v * Scale); }
}
public static class AmoDraw {
    public static GraphicsPath Round(RectangleF r, float rad) {
        GraphicsPath p = new GraphicsPath();
        float d = Math.Min(rad * 2f, Math.Min(r.Width, r.Height));
        if (d <= 1f) { p.AddRectangle(r); return p; }
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure(); return p;
    }
    public static Color Mix(Color a, Color b, float t) {
        if (t < 0) t = 0; if (t > 1) t = 1;
        return Color.FromArgb((int)(a.A + (b.A - a.A) * t), (int)(a.R + (b.R - a.R) * t), (int)(a.G + (b.G - a.G) * t), (int)(a.B + (b.B - a.B) * t));
    }
    public static Color ParentBack(Control c) {
        Control p = c.Parent;
        while (p != null) { if (p.BackColor.A == 255) return p.BackColor; p = p.Parent; }
        return AmoTheme.Bg;
    }
    public static void Prep(Graphics g) { g.SmoothingMode = SmoothingMode.AntiAlias; g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit; g.PixelOffsetMode = PixelOffsetMode.HighQuality; }
}

public class AmoCard : Panel {
    Color fill = AmoTheme.Card; Color border = AmoTheme.Border;
    public int Radius = 16;
    public Color Fill { get { return fill; } set { fill = value; BackColor = value; Invalidate(); } }
    public Color BorderColor { get { return border; } set { border = value; Invalidate(); } }
    public AmoCard() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
        BackColor = fill;
    }
    protected override void OnPaintBackground(PaintEventArgs e) {
        Graphics g = e.Graphics; g.Clear(AmoDraw.ParentBack(this)); AmoDraw.Prep(g);
        RectangleF r = new RectangleF(0.5f, 0.5f, Width - 1.5f, Height - 1.5f);
        using (GraphicsPath p = AmoDraw.Round(r, AmoTheme.S(Radius))) {
            using (SolidBrush b = new SolidBrush(fill)) g.FillPath(b, p);
            if (border.A > 0) using (Pen pen = new Pen(border)) g.DrawPath(pen, p);
        }
    }
}

public class AmoButton : Control {
    float t = 0; bool hover = false, down = false, sel = false, accent = false; Timer tm;
    public int Radius = 10;
    public string Glyph = "";
    string sub = "";
    public ContentAlignment Align = ContentAlignment.MiddleCenter;
    public bool Selected { get { return sel; } set { if (sel != value) { sel = value; Invalidate(); } } }
    public bool Accent { get { return accent; } set { if (accent != value) { accent = value; Invalidate(); } } }
    public string SubText { get { return sub; } set { sub = value ?? ""; Invalidate(); } }
    public AmoButton() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
        Cursor = Cursors.Hand; ForeColor = AmoTheme.Text; Font = new Font("Segoe UI", 9.5f);
        tm = new Timer(); tm.Interval = 15; tm.Tick += Step;
    }
    void Step(object s, EventArgs e) {
        float target = hover ? 1f : 0f; t += (target - t) * 0.22f;
        if (Math.Abs(target - t) < 0.02f) { t = target; tm.Stop(); }
        Invalidate();
    }
    protected override void OnMouseEnter(EventArgs e) { hover = true; tm.Start(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hover = false; down = false; tm.Start(); base.OnMouseLeave(e); }
    protected override void OnMouseDown(MouseEventArgs e) { down = true; Invalidate(); base.OnMouseDown(e); }
    protected override void OnMouseUp(MouseEventArgs e) { down = false; Invalidate(); base.OnMouseUp(e); }
    protected override void OnEnabledChanged(EventArgs e) { Invalidate(); base.OnEnabledChanged(e); }
    protected override void OnTextChanged(EventArgs e) { Invalidate(); base.OnTextChanged(e); }
    protected override void Dispose(bool d) { if (d) tm.Dispose(); base.Dispose(d); }
    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics; g.Clear(AmoDraw.ParentBack(this)); AmoDraw.Prep(g);
        bool hi = accent || sel;
        Color baseC = hi ? AmoTheme.AccentDark : AmoTheme.Card2;
        Color hovC = hi ? AmoDraw.Mix(AmoTheme.AccentDark, AmoTheme.Accent, 0.45f) : AmoTheme.Hover;
        Color fill = Enabled ? AmoDraw.Mix(baseC, hovC, t) : AmoDraw.Mix(AmoTheme.Card2, AmoTheme.Card, 0.5f);
        if (down) fill = AmoDraw.Mix(fill, Color.Black, 0.25f);
        Color border = hi ? AmoTheme.Accent : AmoDraw.Mix(AmoTheme.Border, AmoTheme.Accent, t * 0.7f);
        if (!Enabled) border = AmoTheme.Border;
        RectangleF r = new RectangleF(0.5f, 0.5f, Width - 1.5f, Height - 1.5f);
        using (GraphicsPath p = AmoDraw.Round(r, AmoTheme.S(Radius))) {
            using (SolidBrush b = new SolidBrush(fill)) g.FillPath(b, p);
            using (Pen pen = new Pen(border, sel ? 1.6f * AmoTheme.Scale : 1f)) g.DrawPath(pen, p);
        }
        if (sel) {
            using (SolidBrush ab = new SolidBrush(AmoTheme.Accent))
            using (GraphicsPath bar = AmoDraw.Round(new RectangleF(AmoTheme.S(5), Height * 0.25f, AmoTheme.S(3), Height * 0.5f), AmoTheme.S(2))) g.FillPath(ab, bar);
        }
        Color fc = !Enabled ? AmoTheme.Dim : (hi ? Color.White : ForeColor);
        int pad = AmoTheme.S(14);
        bool left = Align == ContentAlignment.MiddleLeft || sub.Length > 0;
        int gw = 0;
        Font gf = null;
        if (Glyph.Length > 0) { gf = new Font("Segoe MDL2 Assets", Font.SizeInPoints); gw = AmoTheme.S(24); }
        try {
            if (left) {
                int x = pad;
                if (gf != null) { TextRenderer.DrawText(g, Glyph, gf, new Rectangle(x, 0, gw, Height), fc, TextFormatFlags.VerticalCenter | TextFormatFlags.Left); x += gw; }
                if (sub.Length > 0) {
                    using (Font bf = new Font(Font, FontStyle.Bold)) {
                        TextRenderer.DrawText(g, Text, bf, new Rectangle(x, AmoTheme.S(6), Width - x - pad, Height / 2), fc, TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
                    }
                    using (Font sf = new Font("Segoe UI", 8.5f)) {
                        TextRenderer.DrawText(g, sub, sf, new Rectangle(x, Height / 2, Width - x - pad, Height / 2 - AmoTheme.S(4)), hi ? AmoTheme.Text : AmoTheme.Dim, TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
                    }
                } else {
                    TextRenderer.DrawText(g, Text, Font, new Rectangle(x, 0, Width - x - pad, Height), fc, TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
                }
            } else {
                Size ts = TextRenderer.MeasureText(g, Text, Font);
                int total = ts.Width + (gf != null ? gw : 0);
                int x = Math.Max(AmoTheme.S(4), (Width - total) / 2);
                if (gf != null) { TextRenderer.DrawText(g, Glyph, gf, new Rectangle(x, 0, gw, Height), fc, TextFormatFlags.VerticalCenter | TextFormatFlags.Left); x += gw; }
                TextRenderer.DrawText(g, Text, Font, new Rectangle(x, 0, Width - x, Height), fc, TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
            }
        } finally { if (gf != null) gf.Dispose(); }
    }
}

public class AmoToggle : Control {
    bool chk = false, hover = false; float t = 0, h = 0; Timer tm;
    public event EventHandler CheckedChanged;
    public bool Checked {
        get { return chk; }
        set { if (chk != value) { chk = value; tm.Start(); if (CheckedChanged != null) CheckedChanged(this, EventArgs.Empty); } }
    }
    public void SetSilently(bool v) { chk = v; t = v ? 1f : 0f; Invalidate(); }
    public AmoToggle() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
        Cursor = Cursors.Hand; ForeColor = AmoTheme.Text; Font = new Font("Segoe UI", 9.5f);
        tm = new Timer(); tm.Interval = 15; tm.Tick += Step;
    }
    void Step(object s, EventArgs e) {
        float tt = chk ? 1f : 0f, th = hover ? 1f : 0f;
        t += (tt - t) * 0.25f; h += (th - h) * 0.25f;
        if (Math.Abs(tt - t) < 0.02f && Math.Abs(th - h) < 0.02f) { t = tt; h = th; tm.Stop(); }
        Invalidate();
    }
    protected override void OnClick(EventArgs e) { Checked = !Checked; base.OnClick(e); }
    protected override void OnMouseEnter(EventArgs e) { hover = true; tm.Start(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hover = false; tm.Start(); base.OnMouseLeave(e); }
    protected override void Dispose(bool d) { if (d) tm.Dispose(); base.Dispose(d); }
    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics; g.Clear(AmoDraw.ParentBack(this)); AmoDraw.Prep(g);
        int w = AmoTheme.S(40), hh = AmoTheme.S(22), y = (Height - hh) / 2;
        RectangleF tr = new RectangleF(0.5f, y + 0.5f, w - 1, hh - 1);
        using (GraphicsPath p = AmoDraw.Round(tr, hh / 2f)) {
            using (SolidBrush b = new SolidBrush(AmoDraw.Mix(AmoDraw.Mix(AmoTheme.Card2, AmoTheme.Hover, h), AmoTheme.Accent, t))) g.FillPath(b, p);
            using (Pen pen = new Pen(AmoDraw.Mix(AmoTheme.Border, AmoTheme.Accent, Math.Max(t, h * 0.6f)))) g.DrawPath(pen, p);
        }
        float kd = hh - AmoTheme.S(6);
        float kx = AmoTheme.S(3) + (w - kd - AmoTheme.S(6)) * t;
        using (SolidBrush kb = new SolidBrush(Color.White)) g.FillEllipse(kb, kx, y + AmoTheme.S(3), kd, kd);
        TextRenderer.DrawText(g, Text, Font, new Rectangle(w + AmoTheme.S(10), 0, Width - w - AmoTheme.S(10), Height), AmoDraw.Mix(AmoTheme.Dim, AmoTheme.Text, Math.Max(t, h)), TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
    }
}

public class AmoSlider : Control {
    int min = 0, max = 100, val = 0; bool drag = false, hover = false; float t = 0; Timer tm;
    public int DefaultValue = 0;
    public event EventHandler ValueChanged;
    public int Minimum { get { return min; } set { min = value; if (val < min) val = min; Invalidate(); } }
    public int Maximum { get { return max; } set { max = value; if (val > max) val = max; Invalidate(); } }
    public int Value {
        get { return val; }
        set { int v = Math.Max(min, Math.Min(max, value)); if (v != val) { val = v; Invalidate(); if (ValueChanged != null) ValueChanged(this, EventArgs.Empty); } }
    }
    public void SetSilently(int v) { val = Math.Max(min, Math.Min(max, v)); Invalidate(); }
    public AmoSlider() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint | ControlStyles.Selectable, true);
        Cursor = Cursors.Hand; TabStop = true;
        tm = new Timer(); tm.Interval = 15; tm.Tick += Step;
    }
    int Pad { get { return AmoTheme.S(12); } }
    int FromX(int x) {
        float w = Math.Max(1, Width - 2 * Pad);
        float f = (x - Pad) / w; if (f < 0) f = 0; if (f > 1) f = 1;
        return (int)Math.Round(min + f * (max - min));
    }
    float ToX(int v) { return Pad + (max == min ? 0 : (v - min) / (float)(max - min)) * (Width - 2 * Pad); }
    void Step(object s, EventArgs e) {
        float target = (hover || drag) ? 1f : 0f; t += (target - t) * 0.25f;
        if (Math.Abs(target - t) < 0.02f) { t = target; tm.Stop(); }
        Invalidate();
    }
    protected override void OnMouseDown(MouseEventArgs e) { if (e.Button == MouseButtons.Left) { drag = true; Focus(); Value = FromX(e.X); tm.Start(); } base.OnMouseDown(e); }
    protected override void OnMouseMove(MouseEventArgs e) { if (drag) Value = FromX(e.X); base.OnMouseMove(e); }
    protected override void OnMouseUp(MouseEventArgs e) { drag = false; tm.Start(); base.OnMouseUp(e); }
    protected override void OnMouseEnter(EventArgs e) { hover = true; tm.Start(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hover = false; tm.Start(); base.OnMouseLeave(e); }
    protected override void OnDoubleClick(EventArgs e) { Value = DefaultValue; base.OnDoubleClick(e); }
    protected override void OnMouseWheel(MouseEventArgs e) {
        Value = val + (e.Delta > 0 ? 1 : -1);
        HandledMouseEventArgs h = e as HandledMouseEventArgs; if (h != null) h.Handled = true;
        base.OnMouseWheel(e);
    }
    protected override bool IsInputKey(Keys k) { return k == Keys.Left || k == Keys.Right || k == Keys.Up || k == Keys.Down || base.IsInputKey(k); }
    protected override void OnKeyDown(KeyEventArgs e) {
        if (e.KeyCode == Keys.Left || e.KeyCode == Keys.Down) Value = val - 1;
        else if (e.KeyCode == Keys.Right || e.KeyCode == Keys.Up) Value = val + 1;
        else if (e.KeyCode == Keys.PageUp) Value = val + 5;
        else if (e.KeyCode == Keys.PageDown) Value = val - 5;
        else if (e.KeyCode == Keys.Home) Value = min;
        else if (e.KeyCode == Keys.End) Value = max;
        base.OnKeyDown(e);
    }
    protected override void OnGotFocus(EventArgs e) { Invalidate(); base.OnGotFocus(e); }
    protected override void OnLostFocus(EventArgs e) { Invalidate(); base.OnLostFocus(e); }
    protected override void Dispose(bool d) { if (d) tm.Dispose(); base.Dispose(d); }
    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics; g.Clear(AmoDraw.ParentBack(this)); AmoDraw.Prep(g);
        float cy = Height / 2f, th = AmoTheme.S(6);
        RectangleF tr = new RectangleF(Pad, cy - th / 2, Width - 2 * Pad, th);
        using (GraphicsPath p = AmoDraw.Round(tr, th / 2)) using (SolidBrush b = new SolidBrush(AmoTheme.Card2)) g.FillPath(b, p);
        float origin = (min < 0 && max > 0) ? ToX(0) : Pad;
        float x = ToX(val);
        float a = Math.Min(origin, x), bx = Math.Max(origin, x);
        if (bx - a > 1) {
            RectangleF fr = new RectangleF(a, cy - th / 2, bx - a, th);
            using (LinearGradientBrush gb = new LinearGradientBrush(new RectangleF(Pad - 1, 0, Width - 2 * Pad + 2, 1), AmoTheme.Accent, AmoTheme.Cyan, 0f))
            using (GraphicsPath p = AmoDraw.Round(fr, th / 2)) g.FillPath(gb, p);
        }
        float dx = ToX(DefaultValue);
        using (Pen dp = new Pen(AmoTheme.Dim, 1f)) g.DrawLine(dp, dx, cy + th, dx, cy + th + AmoTheme.S(4));
        float r = AmoTheme.S(7) + AmoTheme.S(2) * t;
        if (t > 0.01f || Focused) {
            float gr = r + AmoTheme.S(5);
            using (SolidBrush glow = new SolidBrush(Color.FromArgb((int)(70 * Math.Max(t, Focused ? 0.5f : 0f)), AmoTheme.Accent))) g.FillEllipse(glow, x - gr, cy - gr, gr * 2, gr * 2);
        }
        using (SolidBrush kb = new SolidBrush(Color.White)) g.FillEllipse(kb, x - r, cy - r, r * 2, r * 2);
        using (Pen kp = new Pen(AmoTheme.Accent, 2f * AmoTheme.Scale)) g.DrawEllipse(kp, x - r, cy - r, r * 2, r * 2);
    }
}

public class AmoTile : Control {
    public string Title = "", Desc = "", Cat = "";
    public bool IsCustom = false;
    public double[] Curve;
    bool act = false, hover = false; float t = 0; Timer tm;
    static int[][] rainbow;
    static Font tf, df, bf;
    public bool Active { get { return act; } set { if (act != value) { act = value; Invalidate(); } } }
    static AmoTile() {
        rainbow = new int[48][];
        for (int j = 0; j < 48; j++) {
            double hh = j / 48.0 * 6.0, x = 1 - Math.Abs((hh % 2) - 1);
            double r = 0, g = 0, b = 0;
            switch (((int)Math.Floor(hh)) % 6) {
                case 0: r = 1; g = x; break; case 1: r = x; g = 1; break; case 2: g = 1; b = x; break;
                case 3: g = x; b = 1; break; case 4: r = x; b = 1; break; default: r = 1; b = x; break;
            }
            rainbow[j] = new int[] { (int)(r * 220), (int)(g * 220), (int)(b * 220) };
        }
        tf = new Font("Segoe UI", 10.5f, FontStyle.Bold); df = new Font("Segoe UI", 8.5f); bf = new Font("Segoe UI", 7.5f, FontStyle.Bold);
    }
    public AmoTile() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
        Cursor = Cursors.Hand; tm = new Timer(); tm.Interval = 15; tm.Tick += Step;
    }
    void Step(object s, EventArgs e) {
        float target = hover ? 1f : 0f; t += (target - t) * 0.2f;
        if (Math.Abs(target - t) < 0.02f) { t = target; tm.Stop(); }
        Invalidate();
    }
    protected override void OnMouseEnter(EventArgs e) { hover = true; tm.Start(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hover = false; tm.Start(); base.OnMouseLeave(e); }
    protected override void Dispose(bool d) { if (d) tm.Dispose(); base.Dispose(d); }
    static Color C(double v) { int i = (int)(Math.Max(0, Math.Min(1, v)) * 255); return Color.FromArgb(i, i, i); }
    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics; g.Clear(AmoDraw.ParentBack(this)); AmoDraw.Prep(g);
        float lift = AmoTheme.S(4) * t;
        RectangleF r = new RectangleF(AmoTheme.S(3), AmoTheme.S(6) - lift, Width - AmoTheme.S(6) - 1, Height - AmoTheme.S(10) - 1);
        float rad = AmoTheme.S(14);
        if (t > 0.01f || act) {
            float glowA = act ? 0.9f : t;
            for (int i = 3; i >= 1; i--) {
                RectangleF gr = RectangleF.Inflate(r, i * AmoTheme.S(1.5f), i * AmoTheme.S(1.5f));
                gr.Offset(0, AmoTheme.S(2) * t);
                using (GraphicsPath gp = AmoDraw.Round(gr, rad + i * 2))
                using (Pen gpn = new Pen(Color.FromArgb((int)(40 * glowA / i), AmoTheme.Accent), AmoTheme.S(2))) g.DrawPath(gpn, gp);
            }
        }
        Color fill = act ? AmoDraw.Mix(AmoTheme.AccentDark, AmoTheme.Hover, t * 0.5f) : AmoDraw.Mix(AmoTheme.Card2, AmoTheme.Hover, t);
        Color border = act ? AmoTheme.Accent : AmoDraw.Mix(AmoTheme.Border, AmoTheme.Accent, t);
        using (GraphicsPath p = AmoDraw.Round(r, rad)) {
            using (SolidBrush b = new SolidBrush(fill)) g.FillPath(b, p);
            using (Pen pen = new Pen(border, act ? 1.8f * AmoTheme.Scale : 1f)) g.DrawPath(pen, p);
        }
        int x0 = (int)r.X + AmoTheme.S(12), w = (int)r.Width - AmoTheme.S(24);
        int top = (int)r.Y;
        TextRenderer.DrawText(g, Title, tf, new Rectangle(x0, top + AmoTheme.S(9), w - AmoTheme.S(40), AmoTheme.S(22)), IsCustom ? AmoTheme.Cyan : Color.White, TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
        TextRenderer.DrawText(g, Desc, df, new Rectangle(x0, top + AmoTheme.S(32), w, AmoTheme.S(32)), AmoTheme.Dim, TextFormatFlags.Left | TextFormatFlags.WordBreak | TextFormatFlags.EndEllipsis);
        if (act) {
            RectangleF pill = new RectangleF(r.Right - AmoTheme.S(46), top + AmoTheme.S(10), AmoTheme.S(36), AmoTheme.S(18));
            using (GraphicsPath pp = AmoDraw.Round(pill, AmoTheme.S(9))) using (SolidBrush pb = new SolidBrush(AmoTheme.Accent)) g.FillPath(pb, pp);
            TextRenderer.DrawText(g, "ON", bf, Rectangle.Round(pill), Color.White, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        } else if (IsCustom) {
            RectangleF pill = new RectangleF(r.Right - AmoTheme.S(50), top + AmoTheme.S(10), AmoTheme.S(40), AmoTheme.S(18));
            using (GraphicsPath pp = AmoDraw.Round(pill, AmoTheme.S(9))) using (Pen pp2 = new Pen(AmoTheme.Cyan)) g.DrawPath(pp2, pp);
            TextRenderer.DrawText(g, "MINE", bf, Rectangle.Round(pill), AmoTheme.Cyan, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }
        if (Curve == null) return;
        int sh = AmoTheme.S(12), gap = AmoTheme.S(3);
        int y1 = (int)r.Bottom - AmoTheme.S(12) - 2 * sh - gap, y2 = y1 + sh + gap;
        RectangleF strips = new RectangleF(x0, y1, w, 2 * sh + gap);
        using (GraphicsPath clip = AmoDraw.Round(strips, AmoTheme.S(6))) {
            Region old = g.Clip; g.SetClip(clip, CombineMode.Intersect);
            int n = 48;
            for (int j = 0; j < n; j++) {
                int xa = x0 + (int)(j * (float)w / n), xb = x0 + (int)((j + 1) * (float)w / n) + 1;
                int i = (int)(j * 255.0 / (n - 1));
                using (SolidBrush b1 = new SolidBrush(Color.FromArgb((int)(Curve[i] * 255), (int)(Curve[256 + i] * 255), (int)(Curve[512 + i] * 255)))) g.FillRectangle(b1, xa, y1, xb - xa, sh);
                int[] rb = rainbow[j];
                using (SolidBrush b2 = new SolidBrush(Color.FromArgb((int)(Curve[rb[0]] * 255), (int)(Curve[256 + rb[1]] * 255), (int)(Curve[512 + rb[2]] * 255)))) g.FillRectangle(b2, xa, y2, xb - xa, sh);
            }
            g.Clip = old;
        }
    }
}

public class AmoAvatar : Control {
    Image img; float ang = 0; Timer tm;
    public string Initials = "R";
    public Image Picture { get { return img; } set { img = value; Invalidate(); } }
    public AmoAvatar() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
        tm = new Timer(); tm.Interval = 30; tm.Tick += delegate { if (Visible && Parent != null && Parent.Visible) { ang = (ang + 3f) % 360f; Invalidate(); } }; tm.Start();
    }
    protected override void Dispose(bool d) { if (d) tm.Dispose(); base.Dispose(d); }
    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics; g.Clear(AmoDraw.ParentBack(this)); AmoDraw.Prep(g); g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        int d = Math.Min(Width, Height) - 2;
        Rectangle ring = new Rectangle(1, 1, d, d);
        using (LinearGradientBrush gb = new LinearGradientBrush(ring, AmoTheme.Accent, AmoTheme.Cyan, ang)) g.FillEllipse(gb, ring);
        int inset = AmoTheme.S(5);
        Rectangle inner = Rectangle.Inflate(ring, -inset, -inset);
        using (SolidBrush ib = new SolidBrush(AmoTheme.Card)) g.FillEllipse(ib, inner);
        Rectangle pic = Rectangle.Inflate(inner, -AmoTheme.S(3), -AmoTheme.S(3));
        if (img != null) {
            using (GraphicsPath cp = new GraphicsPath()) {
                cp.AddEllipse(pic);
                g.SetClip(cp);
                float sc = Math.Max(pic.Width / (float)img.Width, pic.Height / (float)img.Height);
                float iw = img.Width * sc, ih = img.Height * sc;
                g.DrawImage(img, pic.X + (pic.Width - iw) / 2f, pic.Y + (pic.Height - ih) / 2f, iw, ih);
                g.ResetClip();
            }
        } else {
            using (Font f = new Font("Segoe UI", Math.Max(8, pic.Height / 4.5f / AmoTheme.Scale), FontStyle.Bold))
                TextRenderer.DrawText(g, Initials, f, pic, Color.White, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }
    }
}

public class AmoGlowLine : Control {
    float off = 0; Timer tm;
    public AmoGlowLine() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
        tm = new Timer(); tm.Interval = 30; tm.Tick += delegate { if (Width > 0) { off = (off + 3f * AmoTheme.Scale) % Width; Invalidate(); } }; tm.Start();
    }
    protected override void Dispose(bool d) { if (d) tm.Dispose(); base.Dispose(d); }
    protected override void OnPaint(PaintEventArgs e) {
        if (Width <= 0) return;
        using (LinearGradientBrush b = new LinearGradientBrush(new RectangleF(off, 0, Width, Math.Max(1, Height)), AmoTheme.Accent, AmoTheme.Cyan, 0f)) {
            ColorBlend cb = new ColorBlend(3);
            cb.Colors = new Color[] { AmoTheme.Accent, AmoTheme.Cyan, AmoTheme.Accent };
            cb.Positions = new float[] { 0f, 0.5f, 1f };
            b.InterpolationColors = cb; b.WrapMode = WrapMode.Tile;
            e.Graphics.FillRectangle(b, ClientRectangle);
        }
    }
}

public class AmoColorTable : ProfessionalColorTable {
    public override Color MenuItemSelected { get { return AmoTheme.Hover; } }
    public override Color MenuItemBorder { get { return AmoTheme.Accent; } }
    public override Color MenuBorder { get { return AmoTheme.Border; } }
    public override Color ToolStripDropDownBackground { get { return AmoTheme.Card2; } }
    public override Color ImageMarginGradientBegin { get { return AmoTheme.Card2; } }
    public override Color ImageMarginGradientMiddle { get { return AmoTheme.Card2; } }
    public override Color ImageMarginGradientEnd { get { return AmoTheme.Card2; } }
    public override Color MenuItemSelectedGradientBegin { get { return AmoTheme.Hover; } }
    public override Color MenuItemSelectedGradientEnd { get { return AmoTheme.Hover; } }
    public override Color MenuItemPressedGradientBegin { get { return AmoTheme.AccentDark; } }
    public override Color MenuItemPressedGradientEnd { get { return AmoTheme.AccentDark; } }
    public override Color SeparatorDark { get { return AmoTheme.Border; } }
    public override Color SeparatorLight { get { return AmoTheme.Card2; } }
}
"@
if (-not ('AmoTile' -as [type])) { Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Windows.Forms, System.Drawing }

[void][AmoNative]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.ToolStripManager]::Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object AmoColorTable))

# ---------- single instance ----------
$mtx = New-Object System.Threading.Mutex($false, 'Local\AmoledDisplayTunerV3')
if (-not $mtx.WaitOne(0)) {
    [System.Windows.Forms.MessageBox]::Show('AMOLED Display Tuner is already running. Look for its icon in the system tray, or press Ctrl+Alt+Insert.', 'AMOLED Display Tuner') | Out-Null
    return
}

# ---------- scale + colours ----------
$gS = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $UiScale = $gS.DpiX / 96.0; $gS.Dispose()
[AmoTheme]::Scale = [float]$UiScale
function Px($v) { [int][Math]::Round($v * $UiScale) }

$cBG = [AmoTheme]::Bg; $cPanel = [AmoTheme]::Card; $cPanel2 = [AmoTheme]::Card2; $cBorder = [AmoTheme]::Border
$cHover = [AmoTheme]::Hover; $cText = [AmoTheme]::Text; $cDim = [AmoTheme]::Dim
$cAccent = [AmoTheme]::Accent; $cAccentDark = [AmoTheme]::AccentDark; $cCyan = [AmoTheme]::Cyan
$cGood = [System.Drawing.Color]::FromArgb(80, 220, 140); $cBad = [System.Drawing.Color]::FromArgb(255, 95, 95); $cWarn = [System.Drawing.Color]::FromArgb(255, 200, 80)

$fTitle = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$fBig   = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Bold)
$fSec   = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$fBody  = New-Object System.Drawing.Font('Segoe UI', 9.5)
$fBold  = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$fSmall = New-Object System.Drawing.Font('Segoe UI', 8.5)
$fMono  = New-Object System.Drawing.Font('Consolas', 9)
$fValue = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

# ---------- settings model ----------
$Specs = @(
    [pscustomobject]@{K='Brightness'; L='Brightness';  Min=20;   Max=150; Def=100; Div=1;   Tip='Software brightness. Under 100 = dimmer, over 100 = brighter (boosts mids).'}
    [pscustomobject]@{K='Contrast';   L='Contrast';    Min=0;    Max=100; Def=0;   Div=1;   Tip='S-curve punch: darker darks + brighter brights.'}
    [pscustomobject]@{K='Black';      L='Black depth'; Min=0;    Max=15;  Def=0;   Div=1;   Tip='Turns near-black into true black. Main AMOLED effect.'}
    [pscustomobject]@{K='Gamma';      L='Gamma';       Min=60;   Max=160; Def=100; Div=100; Tip='Above 1.00 = deeper, richer midtones. Below = lighter.'}
    [pscustomobject]@{K='Shadows';    L='Shadows';     Min=-30;  Max=30;  Def=0;   Div=1;   Tip='Lift (+) or deepen (-) the dark areas.'}
    [pscustomobject]@{K='Highlights'; L='Highlights';  Min=-30;  Max=30;  Def=0;   Div=1;   Tip='Boost (+) or soften (-) the bright areas.'}
    [pscustomobject]@{K='Temp';       L='Temperature'; Min=-100; Max=100; Def=0;   Div=1;   Tip='Left = cool / blue. Right = warm / orange.'}
    [pscustomobject]@{K='Red';        L='Red';         Min=50;   Max=100; Def=100; Div=1;   Tip='Red channel level.'}
    [pscustomobject]@{K='Green';      L='Green';       Min=50;   Max=100; Def=100; Div=1;   Tip='Green channel level.'}
    [pscustomobject]@{K='Blue';       L='Blue';        Min=50;   Max=100; Def=100; Div=1;   Tip='Blue channel level.'}
)
$SpecByK = @{}; foreach ($sp in $Specs) { $SpecByK[$sp.K] = $sp }

function New-Vals { $h = @{}; foreach ($sp in $Specs) { $h[$sp.K] = $sp.Def }; $h }
function Copy-Vals($v) {
    $h = @{}
    foreach ($sp in $Specs) {
        $x = $sp.Def
        if ($v -and $v.ContainsKey($sp.K)) { $x = [int]$v[$sp.K] }
        $h[$sp.K] = [Math]::Min($sp.Max, [Math]::Max($sp.Min, $x))
    }
    $h
}

# ---------- FILTER LIBRARY ----------
$Categories = @('AMOLED', 'Contrast', 'Vibrant', 'Gaming', 'Focus', 'Reading', 'Cinema', 'Eye Care')
$Filters = New-Object System.Collections.ArrayList
function F($name, $cat, $desc, $vals) { [void]$Filters.Add([pscustomobject]@{ Name = $name; Cat = $cat; Desc = $desc; Vals = $vals }) }

# AMOLED family
F 'AMOLED Lite'          'AMOLED'   'Gentle deep blacks, natural colours'     @{Black=2; Contrast=20; Gamma=105}
F 'Super AMOLED'         'AMOLED'   'Classic deep-black phone look'           @{Black=3; Contrast=35; Gamma=110}
F 'Super AMOLED Plus'    'AMOLED'   'Deeper blacks, brighter pop'             @{Black=4; Contrast=42; Gamma=112; Highlights=5}
F 'Ultra Super AMOLED'   'AMOLED'   'Maximum punch, inky blacks'              @{Black=6; Contrast=55; Gamma=115; Highlights=10; Temp=-10}
F 'Dynamic AMOLED'       'AMOLED'   'Flagship look, HDR-style highlights'     @{Black=4; Contrast=45; Gamma=110; Highlights=12; Shadows=-5; Temp=-8}
F 'AMOLED Max'           'AMOLED'   'Extreme contrast, cool and sharp'        @{Black=8; Contrast=65; Gamma=118; Highlights=14; Temp=-15}
F 'OLED Pure Black'      'AMOLED'   'True black backgrounds'                  @{Black=10; Contrast=40; Gamma=115; Shadows=-10}
F 'QLED Bright'          'AMOLED'   'Bright, clean, cool tone'                @{Brightness=112; Contrast=35; Highlights=12; Temp=-12}
# Contrast
F 'Soft Contrast'        'Contrast' 'A little extra depth'                    @{Contrast=12}
F 'High Contrast'        'Contrast' 'Strong darks and brights'                @{Black=3; Contrast=50}
F 'Ultra Contrast'       'Contrast' 'As strong as it gets'                    @{Black=6; Contrast=80; Gamma=110}
F 'HDR Look'             'Contrast' 'Open shadows, bright highlights'         @{Black=2; Contrast=40; Shadows=12; Highlights=15}
F 'Crisp'                'Contrast' 'Sharp, clean text and edges'             @{Contrast=30; Gamma=104; Highlights=6}
# Vibrant
F 'Vivid'                'Vibrant'  'Colours that pop'                        @{Contrast=40; Gamma=108; Highlights=8; Temp=-5}
F 'Ultra Vivid'          'Vibrant'  'Bold, punchy, saturated feel'            @{Black=4; Contrast=60; Gamma=112; Highlights=12; Temp=-10}
F 'Neon Pop'             'Vibrant'  'Cool neon gamer vibe'                    @{Black=5; Contrast=55; Highlights=10; Temp=-30}
F 'Warm Glow'            'Vibrant'  'Golden, cosy colour'                     @{Contrast=30; Highlights=8; Temp=40}
F 'Cool Ice'             'Vibrant'  'Icy blue, clean look'                    @{Contrast=30; Temp=-45}
# Gaming
F 'Gaming Pro'           'Gaming'   'Punchy with visible shadows'             @{Contrast=20; Gamma=90; Shadows=15; Highlights=5}
F 'FPS Enemy Spotter'    'Gaming'   'Lights up dark corners'                  @{Brightness=105; Contrast=25; Gamma=82; Shadows=28; Temp=-10}
F 'Esports Bright'       'Gaming'   'Bright and clear for ranked'             @{Brightness=115; Contrast=25; Shadows=20; Temp=-10}
F 'Battle Royale'        'Gaming'   'Spot players at long range'              @{Contrast=30; Gamma=88; Shadows=20; Highlights=8; Temp=-8}
F 'Horror / Dark Games'  'Gaming'   'See in the dark without washing out'     @{Contrast=15; Gamma=85; Shadows=25}
F 'RPG Rich'             'Gaming'   'Rich, cinematic worlds'                  @{Black=3; Contrast=40; Gamma=110; Highlights=6; Temp=10}
F 'Racing Speed'         'Gaming'   'Bright, fast, high energy'               @{Brightness=105; Contrast=45; Highlights=15; Temp=-15}
F 'Retro Arcade'         'Gaming'   'Old-school CRT warmth'                   @{Black=5; Contrast=50; Temp=15; Green=96}
# Focus
F 'Focus'                'Focus'    'Calm, low-distraction screen'            @{Brightness=92; Contrast=25; Temp=15}
F 'Deep Work'            'Focus'    'Softer, warmer for long sessions'        @{Brightness=85; Contrast=20; Highlights=-8; Temp=30}
F 'Coding Dark'          'Focus'    'Dark themes look sharper'                @{Black=5; Contrast=30; Gamma=108; Highlights=-5; Temp=10}
F 'Study Mode'           'Focus'    'Clear and gentle on the eyes'            @{Brightness=95; Contrast=15; Temp=20}
# Reading
F 'Reading'              'Reading'  'Warm and easy for text'                  @{Brightness=85; Contrast=10; Temp=35}
F 'Paper'                'Reading'  'Feels like reading on paper'             @{Brightness=90; Contrast=8; Highlights=-10; Temp=45}
F 'Sepia'                'Reading'  'Old book tone'                           @{Brightness=90; Contrast=10; Temp=70; Blue=85}
F 'E-Ink Soft'           'Reading'  'Low glare, soft whites'                  @{Contrast=25; Highlights=-15; Temp=25}
F 'Night Reading'        'Reading'  'Dim and warm for late reading'           @{Brightness=70; Highlights=-10; Temp=85}
# Cinema
F 'Cinema'               'Cinema'   'Rich, warm, filmic'                      @{Black=2; Contrast=20; Gamma=108; Temp=25}
F 'Movie Night'          'Cinema'   'Dark room movie mode'                    @{Brightness=85; Black=3; Contrast=25; Gamma=110; Temp=30}
F 'Anime'                'Cinema'   'Bright, clean, colourful'                @{Contrast=35; Gamma=104; Highlights=10; Temp=-12}
F 'Film Noir'            'Cinema'   'Dramatic shadows'                        @{Black=6; Contrast=60; Gamma=112; Temp=5}
F 'Sports Live'          'Cinema'   'Bright stadium look'                     @{Brightness=108; Contrast=30; Highlights=10; Temp=-8}
# Eye Care
F 'Eye Comfort'          'Eye Care' 'Softer and warmer all day'               @{Brightness=90; Contrast=5; Temp=45}
F 'Blue Light Block'     'Eye Care' 'Cuts blue light'                         @{Temp=70; Blue=60}
F 'Night'                'Eye Care' 'Warm and dim for night'                  @{Brightness=75; Black=2; Contrast=15; Gamma=105; Temp=80}
F 'Night Ultra Warm'     'Eye Care' 'Strongest night filter'                  @{Brightness=60; Temp=100; Green=90; Blue=60}
F 'Low Light Dim'        'Eye Care' 'Extra dim for dark rooms'                @{Brightness=45; Temp=30}
F 'Normal'               'Eye Care' 'Original colours, no filter'             @{}

$Builtin = [ordered]@{}
$FilterByName = @{}
foreach ($f in $Filters) { $Builtin[$f.Name] = $f.Vals; $FilterByName[$f.Name] = $f }

# ---------- config ----------
$CfgDir  = Join-Path $env:APPDATA 'AmoledDisplayTuner'
$CfgFile = Join-Path $CfgDir 'config-v2.json'
$AvatarFile = Join-Path $CfgDir 'creator.jpg'
$AvatarTmp  = Join-Path $CfgDir 'creator.part'
$Startup = Join-Path ([Environment]::GetFolderPath('Startup')) 'AmoledDisplayTuner.cmd'
$PermCopy = Join-Path $CfgDir 'AmoledDisplayTuner.bat'
$RunKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RunName  = 'AmoledDisplayTuner'

function To-Hash($o) { $h = @{}; if ($o) { foreach ($p in $o.PSObject.Properties) { $h[$p.Name] = $p.Value } }; $h }
function Load-Config {
    $c = @{ Displays = @{}; Custom = @{}; Active = @{}; Modified = @{}; Lock = $false; Link = $false; Tray = $true; Permanent = $false; WinW = 0; WinH = 0; WinMax = $false }
    if (Test-Path $CfgFile) {
        try {
            $o = Get-Content $CfgFile -Raw | ConvertFrom-Json
            foreach ($p in (To-Hash $o.Displays).GetEnumerator()) { $c.Displays[$p.Key] = Copy-Vals (To-Hash $p.Value) }
            foreach ($p in (To-Hash $o.Custom).GetEnumerator())   { $c.Custom[$p.Key]   = Copy-Vals (To-Hash $p.Value) }
            foreach ($p in (To-Hash $o.Active).GetEnumerator())   { $c.Active[$p.Key]   = [string]$p.Value }
            foreach ($p in (To-Hash $o.Modified).GetEnumerator()) { $c.Modified[$p.Key] = [bool]$p.Value }
            if ($o.PSObject.Properties['WinW'])   { $c.WinW = [int]$o.WinW; $c.WinH = [int]$o.WinH; $c.WinMax = [bool]$o.WinMax }
            if ($o.PSObject.Properties['Lock']) { $c.Lock = [bool]$o.Lock }
            if ($o.PSObject.Properties['Link']) { $c.Link = [bool]$o.Link }
            if ($o.PSObject.Properties['Tray']) { $c.Tray = [bool]$o.Tray }
            if ($o.PSObject.Properties['Permanent']) { $c.Permanent = [bool]$o.Permanent }
        } catch {}
    }
    $c
}
function Save-Config {
    try {
        if (-not (Test-Path $CfgDir)) { New-Item -ItemType Directory -Path $CfgDir | Out-Null }
        $Cfg | ConvertTo-Json -Depth 5 | Set-Content -Path $CfgFile -Encoding UTF8
    } catch {}
}
$Cfg = Load-Config

function Preset-Vals($name) {
    if ($Builtin.Contains($name)) { $v = New-Vals; foreach ($k in $Builtin[$name].Keys) { $v[$k] = $Builtin[$name][$k] }; return $v }
    if ($Cfg.Custom.ContainsKey($name)) { return (Copy-Vals $Cfg.Custom[$name]) }
    New-Vals
}

# ---------- picture maths ----------
function Get-Curve($v) {
    $b = $v.Brightness / 100.0; $c = $v.Contrast / 100.0; $k = $v.Black / 100.0; $g = $v.Gamma / 100.0
    $sh = $v.Shadows / 100.0; $hl = $v.Highlights / 100.0; $t = $v.Temp / 100.0
    if ($t -ge 0) { $tr = 1.0; $tg = 1.0 - 0.12 * $t; $tb = 1.0 - 0.38 * $t }
    else { $u = -$t; $tr = 1.0 - 0.28 * $u; $tg = 1.0 - 0.10 * $u; $tb = 1.0 }
    $gain = @(($tr * $v.Red / 100.0), ($tg * $v.Green / 100.0), ($tb * $v.Blue / 100.0))
    $out = New-Object 'double[]' 768
    for ($i = 0; $i -lt 256; $i++) {
        $x = $i / 255.0
        if ($k -gt 0) { $x = [Math]::Max(0.0, ($x - $k) / (1.0 - $k)) }
        $x += $sh * 4.0 * $x * (1.0 - $x) * (1.0 - $x)
        $x += $hl * 4.0 * $x * $x * (1.0 - $x)
        $x = [Math]::Min(1.0, [Math]::Max(0.0, $x))
        $sc = $x * $x * (3.0 - 2.0 * $x); $x = $x * (1.0 - $c) + $sc * $c
        $x = [Math]::Pow($x, $g)
        if ($b -le 1.0) { $x = $x * $b } else { $x = 1.0 - [Math]::Pow(1.0 - $x, $b) }
        for ($ch = 0; $ch -lt 3; $ch++) { $out[$ch * 256 + $i] = [Math]::Min(1.0, [Math]::Max(0.0, $x * $gain[$ch])) }
    }
    return ,$out
}
function New-Ramp($v) {
    $cv = Get-Curve $v
    $r = New-Object 'uint16[]' 768
    for ($j = 0; $j -lt 768; $j++) { $r[$j] = [uint16][Math]::Round($cv[$j] * 65535) }
    return ,$r
}

# ---------- displays ----------
$Scr = @([System.Windows.Forms.Screen]::AllScreens | Sort-Object DeviceName)
function Get-MonitorNames {
    $map = @{}
    $wmi = @()
    try { $wmi = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop) } catch {}
    foreach ($s in $Scr) {
        $name = $null
        try {
            $info = [AmoNative]::MonitorInfo($s.DeviceName)
            if ($info[1]) {
                $p = $info[1].Split('#')
                if ($p.Count -ge 3) {
                    $inst = "DISPLAY\$($p[1])\$($p[2])"
                    foreach ($m in $wmi) {
                        if ($m.InstanceName -and $m.InstanceName.StartsWith($inst, [StringComparison]::OrdinalIgnoreCase) -and $m.UserFriendlyName) {
                            $name = -join ($m.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })
                            break
                        }
                    }
                }
            }
            if (-not $name -and $info[0]) { $name = $info[0] }
        } catch {}
        if (-not $name) { $name = 'Monitor' }
        $map[$s.DeviceName] = $name.Trim()
    }
    $map
}
$Names = Get-MonitorNames

$St = @{ Busy = $false; Off = $false; Holding = $false; Exiting = $false; Sel = 0; PresetIdx = -1
         PresetList = @(); HwPending = @{}; TipShown = $false; IdForms = @(); Page = ''; AnimPage = $null
         Full = $false; PrevBounds = $null; PrevState = 'Normal'; Cat = 'All'; SelTile = ''
         Tray = ($env:AMO_ARGS -match 'tray|autoapply') }

function Get-Vals($dev) { if (-not $Cfg.Displays.ContainsKey($dev)) { $Cfg.Displays[$dev] = New-Vals }; $Cfg.Displays[$dev] }
function Targets { if ($Cfg.Link) { $Scr } else { @($Scr[$St.Sel]) } }
function Center($s) { @(($s.Bounds.X + [int]($s.Bounds.Width / 2)), ($s.Bounds.Y + [int]($s.Bounds.Height / 2))) }

function Apply-Screen($s) {
    $v = if ($St.Off -or $St.Holding) { New-Vals } else { Get-Vals $s.DeviceName }
    [AmoNative]::ApplyRamp($s.DeviceName, (New-Ramp $v))
}
function Apply-All { $ok = $true; foreach ($s in $Scr) { if (-not (Apply-Screen $s)) { $ok = $false } }; Show-Result $ok }


# ======================= UI HELPERS =======================
function Place($c, $x, $y, $w, $h, $parent, $anchor = $null) {
    $c.Location = New-Object System.Drawing.Point((Px $x), (Px $y))
    $c.Size = New-Object System.Drawing.Size((Px $w), (Px $h))
    [void]$parent.Controls.Add($c)
    if ($anchor) { $c.Anchor = $anchor }
}
function New-Label($parent, $text, $x, $y, $w, $h, $font = $fBody, $color = $null, $anchor = $null) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Font = $font; $l.BackColor = [System.Drawing.Color]::Transparent
    $l.ForeColor = if ($color) { $color } else { $cText }
    Place $l $x $y $w $h $parent $anchor; $l
}
function New-Btn($parent, $text, $x, $y, $w, $h, $accent = $false, $anchor = $null, $glyph = '') {
    $b = New-Object AmoButton
    $b.Text = $text; $b.Accent = $accent; $b.Glyph = $glyph
    Place $b $x $y $w $h $parent $anchor; $b
}
function New-Toggle($parent, $text, $x, $y, $w, $h, $anchor = $null) {
    $t = New-Object AmoToggle; $t.Text = $text
    Place $t $x $y $w $h $parent $anchor; $t
}
function New-Card($parent, $x, $y, $w, $h, $anchor = $null, $fill = $null, $radius = 16) {
    $c = New-Object AmoCard
    if ($fill) { $c.Fill = $fill }
    $c.Radius = $radius
    Place $c $x $y $w $h $parent $anchor; $c
}
function New-Line($parent, $x, $y, $w, $anchor = $null) {
    $p = New-Object System.Windows.Forms.Panel; $p.BackColor = $cBorder
    Place $p $x $y $w 1 $parent $anchor; $p
}
function Style-Menu($m) { $m.BackColor = $cPanel2; $m.ForeColor = $cText; $m.Font = $fBody }
function New-MenuItem($text) { $i = New-Object System.Windows.Forms.ToolStripMenuItem $text; $i.ForeColor = $cText; $i }

# ---------- app icon ----------
$bmp = New-Object System.Drawing.Bitmap 32, 32
$gi = [System.Drawing.Graphics]::FromImage($bmp); $gi.SmoothingMode = 'AntiAlias'; $gi.Clear([System.Drawing.Color]::Transparent)
$gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 0, 0, 32, 32), $cAccent, $cCyan, 45.0)
$gi.FillEllipse($gb, 1, 1, 30, 30); $gi.FillEllipse([System.Drawing.Brushes]::Black, 9, 9, 14, 14); $gi.Dispose()
$appIcon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())

# ======================= MAIN WINDOW =======================
$form = New-Object System.Windows.Forms.Form
$form.Text = "$AppName  -  by $($Creator.Short)"
$form.AutoScaleMode = 'None'
$form.ClientSize = New-Object System.Drawing.Size((Px 1180), (Px 760))
$form.MinimumSize = New-Object System.Drawing.Size((Px 1100), (Px 720))
$form.BackColor = $cBG; $form.ForeColor = $cText; $form.Font = $fBody
$form.FormBorderStyle = 'Sizable'; $form.MaximizeBox = $true; $form.StartPosition = 'CenterScreen'
$form.Icon = $appIcon; $form.KeyPreview = $true
$form.add_HandleCreated({ [AmoNative]::StyleWindow($form.Handle) })
$tips = New-Object System.Windows.Forms.ToolTip

# ---------- header ----------
$header = New-Object System.Windows.Forms.Panel; $header.BackColor = $cBG; $header.Size = New-Object System.Drawing.Size((Px 1180), (Px 72)); $header.Dock = 'Top'
[void](New-Label $header 'AMOLED DISPLAY TUNER' 20 10 440 36 $fTitle $cAccent)
[void](New-Label $header "Premium colour, contrast and brightness for every monitor  -  by $($Creator.Short)" 23 44 560 20 $fSmall $cDim)
$glow = New-Object AmoGlowLine; $glow.Height = Px 3; $glow.Dock = 'Bottom'; $header.Controls.Add($glow)

$NavBtns = @{}
$btnFull = New-Btn $header '' 1120 16 42 38 $false 'Top, Right' ([string][char]0xE740)
$tips.SetToolTip($btnFull, 'Full screen (F11)')
$btnFull.add_Click({ Toggle-Fullscreen })
$navX = 1112
foreach ($pair in @(@('About', 'About creator', 164, [char]0xE77B), @('Tune', 'Fine tune', 136, [char]0xE713), @('Filters', 'Filters', 124, [char]0xE790))) {
    $navX -= $pair[2]
    $nb = New-Btn $header $pair[1] $navX 16 $pair[2] 38 $false 'Top, Right' ([string]$pair[3])
    $nb.Font = $fBold; $nb.Tag = $pair[0]; $nb.Radius = 12
    $nb.add_Click({ Show-Page $this.Tag })
    $NavBtns[$pair[0]] = $nb
    $navX -= 8
}

# ---------- footer ----------
$footer = New-Object System.Windows.Forms.Panel; $footer.BackColor = $cBG; $footer.Size = New-Object System.Drawing.Size((Px 1180), (Px 34)); $footer.Dock = 'Bottom'
[void](New-Line $footer 0 0 1180 'Top, Left, Right')
$lblStatus = New-Label $footer '' 18 7 640 22 $fBody $cDim 'Top, Left'
$lnkCopy = New-Object System.Windows.Forms.LinkLabel
$lnkCopy.Text = "$Copyright   |   10vir.me"; $lnkCopy.Font = $fSmall; $lnkCopy.TextAlign = 'MiddleRight'
$lnkCopy.LinkColor = $cDim; $lnkCopy.ActiveLinkColor = $cCyan; $lnkCopy.VisitedLinkColor = $cDim; $lnkCopy.LinkBehavior = 'HoverUnderline'
$lnkCopy.BackColor = [System.Drawing.Color]::Transparent
Place $lnkCopy 660 7 504 22 $footer 'Top, Right'
$lnkCopy.add_LinkClicked({ Open-Url $Creator.Website })

# ---------- page host ----------
$host2 = New-Object System.Windows.Forms.Panel; $host2.BackColor = $cBG; $host2.Dock = 'Fill'
$form.Controls.Add($header); $form.Controls.Add($footer); $form.Controls.Add($host2); $host2.BringToFront()
$host2.Size = New-Object System.Drawing.Size((Px 1180), (Px 654))
function New-Page {
    $p = New-Object System.Windows.Forms.Panel; $p.BackColor = $cBG; $p.Visible = $false
    Place $p 12 12 1156 630 $host2; $p
}
$pageFilters = New-Page; $pageTune = New-Page; $pageAbout = New-Page
$Pages = @{ Filters = $pageFilters; Tune = $pageTune; About = $pageAbout }
function Layout-Pages {
    $w = $host2.ClientSize.Width - (Px 24); $h = $host2.ClientSize.Height - (Px 24)
    if ($w -lt 50 -or $h -lt 50) { return }
    foreach ($p in $Pages.Values) {
        $p.Size = New-Object System.Drawing.Size($w, $h)
        if (-not ($tPage.Enabled -and $p -eq $St.AnimPage)) { $p.Location = New-Object System.Drawing.Point((Px 12), (Px 12)) }
    }
}
$host2.add_Resize({ Layout-Pages })

function Set-Status($msg, $kind = 'info') {
    $lblStatus.Text = $msg
    $lblStatus.ForeColor = switch ($kind) { 'good' { $cGood } 'bad' { $cBad } 'warn' { $cWarn } default { $cDim } }
}
function Show-Result($ok) {
    if (-not $ok) { Set-Status "Windows blocked this strength. Click 'Unlock stronger effects' in Fine tune, then restart." 'bad' }
}

# ---------- dark text prompt ----------
function Ask-Text($title, $prompt, $default) {
    $d = New-Object System.Windows.Forms.Form
    $d.Text = $title; $d.FormBorderStyle = 'FixedDialog'; $d.StartPosition = 'CenterParent'
    $d.MinimizeBox = $false; $d.MaximizeBox = $false; $d.ShowInTaskbar = $false; $d.AutoScaleMode = 'None'
    $d.ClientSize = New-Object System.Drawing.Size((Px 440), (Px 176)); $d.BackColor = $cBG; $d.KeyPreview = $true; $d.Icon = $appIcon
    $d.add_HandleCreated({ [AmoNative]::StyleWindow($this.Handle) })
    [void](New-Label $d $prompt 22 18 396 22 $fBody $cText)
    $box = New-Card $d 22 48 396 44 $null $cPanel2 12
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.BorderStyle = 'None'; $tb.BackColor = $cPanel2; $tb.ForeColor = $cText; $tb.Font = New-Object System.Drawing.Font('Segoe UI', 11)
    $tb.Text = $default
    Place $tb 14 11 368 24 $box
    $ok = New-Btn $d 'Save' 268 116 150 40 $true
    $cn = New-Btn $d 'Cancel' 108 116 150 40
    $ok.add_Click({ $this.FindForm().DialogResult = 'OK' })
    $cn.add_Click({ $this.FindForm().DialogResult = 'Cancel' })
    $d.add_KeyDown({ param($s, $e) if ($e.KeyCode -eq 'Enter') { $s.DialogResult = 'OK' } elseif ($e.KeyCode -eq 'Escape') { $s.DialogResult = 'Cancel' } })
    $d.ActiveControl = $tb; $tb.SelectAll()
    $r = $d.ShowDialog($form)
    $txt = $tb.Text
    $d.Dispose()
    if ($r -eq 'OK' -and -not [string]::IsNullOrWhiteSpace($txt)) { return $txt.Trim() }
    return $null
}

# ================= FILTERS PAGE =================
$cardF = New-Card $pageFilters 0 0 1156 630 'Top, Bottom, Left, Right'
[void](New-Label $cardF 'FILTERS' 20 18 100 24 $fSec $cAccent)
$lblFHint = New-Label $cardF '' 104 20 520 20 $fSmall $cDim

$TargetBtns = @()
$tw = 104; $tx = 1156 - 20 - ($Scr.Count + 1) * ($tw + 6) + 6
[void](New-Label $cardF 'Apply to:' ($tx - 70) 20 66 20 $fSmall $cDim 'Top, Right')
for ($i = 0; $i -lt $Scr.Count; $i++) {
    $b = New-Btn $cardF "Display $($i + 1)" $tx 12 $tw 34 $false 'Top, Right'
    $b.Tag = $i; $tips.SetToolTip($b, $Names[$Scr[$i].DeviceName])
    $b.add_Click({ Set-Link $false; Select-Display ([int]$this.Tag) })
    $TargetBtns += $b; $tx += $tw + 6
}
$btnAllT = New-Btn $cardF 'All displays' $tx 12 $tw 34 $false 'Top, Right'
$btnAllT.add_Click({ Set-Link $true })

$Chips = @()
$cx = 20
foreach ($c in (@('All') + $Categories + @('Mine'))) {
    $label = if ($c -eq 'Mine') { 'My presets' } else { $c }
    $w = 30 + $label.Length * 8
    $b = New-Btn $cardF $label $cx 58 $w 32
    $b.Tag = $c; $b.Font = $fSmall; $b.Radius = 16
    $b.add_Click({ $St.Cat = $this.Tag; Update-Tiles })
    $Chips += $b; $cx += $w + 6
}

$CurveCache = @{}
$flow = New-Object System.Windows.Forms.FlowLayoutPanel
$flow.AutoScroll = $true; $flow.BackColor = $cPanel; $flow.WrapContents = $true
Place $flow 14 100 1128 450 $cardF 'Top, Bottom, Left, Right'
$flow.add_Resize({ Size-Tiles })

# action bar
$bar = New-Card $cardF 14 560 1128 56 'Bottom, Left, Right' $cPanel2 14
$lblSelTitle = New-Label $bar 'Click any filter to apply it' 18 8 360 22 $fBold $cText 'Top, Left'
$lblSelSub = New-Label $bar 'Then customise it and save it as your own preset.' 18 29 370 20 $fSmall $cDim 'Top, Left'
$bPerm = New-Btn $bar 'Apply permanently' 390 10 178 36 $true 'Top, Right' ([string][char]0xE718)
$tips.SetToolTip($bPerm, 'Keep this look after restart, sleep and games')
$bDel  = New-Btn $bar 'Delete' 1006 10 110 36 $false 'Top, Right' ([string][char]0xE74D)
$bRen  = New-Btn $bar 'Rename' 888 10 110 36 $false 'Top, Right' ([string][char]0xE8AC)
$bSave = New-Btn $bar 'Save as my preset' 714 10 166 36 $true 'Top, Right' ([string][char]0xE74E)
$bEdit = New-Btn $bar 'Customise' 576 10 130 36 $false 'Top, Right' ([string][char]0xE70F)
$bEdit.add_Click({ Show-Page 'Tune' })
$bPerm.add_Click({ Set-Permanent (-not $Cfg.Permanent) })
$bSave.add_Click({ Save-NewPreset })
$bRen.add_Click({ Rename-Preset (Current-Name) })
$bDel.add_Click({ Delete-Preset (Current-Name) })

# tile right-click menu
$tileMenu = New-Object System.Windows.Forms.ContextMenuStrip; Style-Menu $tileMenu
$tmApply = New-MenuItem 'Apply'; $tmEdit = New-MenuItem 'Customise...'; $tmDup = New-MenuItem 'Duplicate to My presets'
$tmRen = New-MenuItem 'Rename...'; $tmDel = New-MenuItem 'Delete'
foreach ($it in @($tmApply, $tmEdit, $tmDup, $tmRen, $tmDel)) { [void]$tileMenu.Items.Add($it) }
$tileMenu.add_Opening({
    $t = $tileMenu.SourceControl
    $St.MenuTile = if ($t) { $t.Title } else { '' }
    $isMine = $t -and $t.IsCustom
    $tmRen.Enabled = $isMine; $tmDel.Enabled = $isMine
})
$tmApply.add_Click({ Apply-Preset $St.MenuTile })
$tmEdit.add_Click({ Apply-Preset $St.MenuTile; Show-Page 'Tune' })
$tmDup.add_Click({
    $n = $St.MenuTile + ' (copy)'; $k = 2
    while ($Cfg.Custom.ContainsKey($n) -or $Builtin.Contains($n)) { $n = "$($St.MenuTile) (copy $k)"; $k++ }
    $Cfg.Custom[$n] = Preset-Vals $St.MenuTile; Save-Config; Refresh-Presets; Set-Status "Added to My presets: $n" 'good'
})
$tmRen.add_Click({ Rename-Preset $St.MenuTile })
$tmDel.add_Click({ Delete-Preset $St.MenuTile })

function New-Tile($name, $cat, $desc, $mine) {
    $t = New-Object AmoTile
    $t.Title = $name; $t.Desc = $desc; $t.Cat = $cat; $t.IsCustom = $mine
    $t.Size = New-Object System.Drawing.Size((Px 214), (Px 136))
    $t.Margin = New-Object System.Windows.Forms.Padding(0)
    if ($mine -or -not $CurveCache.ContainsKey($name)) { $CurveCache[$name] = Get-Curve (Preset-Vals $name) }
    $t.Curve = $CurveCache[$name]
    $t.ContextMenuStrip = $tileMenu
    $t.add_MouseClick({ param($s, $e) if ($e.Button -eq 'Left') { Apply-Preset $s.Title } })
    $tips.SetToolTip($t, "$name  -  $desc  (right-click for more)")
    $t
}
function Build-Tiles {
    $flow.SuspendLayout()
    $old = @($flow.Controls); $flow.Controls.Clear(); foreach ($c in $old) { $c.Dispose() }
    foreach ($f in $Filters) { [void]$flow.Controls.Add((New-Tile $f.Name $f.Cat $f.Desc $false)) }
    foreach ($n in ($Cfg.Custom.Keys | Sort-Object)) { [void]$flow.Controls.Add((New-Tile $n 'Mine' 'Your own preset' $true)) }
    $flow.ResumeLayout()
    Update-Tiles
}
function Size-Tiles {
    $avail = $flow.ClientSize.Width - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth - (Px 6)
    if ($avail -lt 100) { return }
    $per = [Math]::Max(1, [Math]::Floor($avail / (Px 216)))
    $tw2 = [int][Math]::Floor($avail / $per)
    $flow.SuspendLayout()
    foreach ($c in $flow.Controls) { if ($c.Width -ne $tw2) { $c.Width = $tw2 } }
    $flow.ResumeLayout()
}
function Update-Tiles {
    $flow.SuspendLayout()
    $dev = $Scr[$St.Sel].DeviceName
    foreach ($c in $flow.Controls) {
        $c.Visible = ($St.Cat -eq 'All' -or $c.Cat -eq $St.Cat)
        $c.Active = (($Cfg.Active[$dev] -eq $c.Title) -and -not $Cfg.Modified[$dev])
    }
    $flow.ResumeLayout()
    foreach ($b in $Chips) { $b.Selected = ($b.Tag -eq $St.Cat) }
    Size-Tiles
}
function Update-TargetBtns {
    for ($i = 0; $i -lt $TargetBtns.Count; $i++) { $TargetBtns[$i].Selected = ((-not $Cfg.Link) -and ($i -eq $St.Sel)) }
    $btnAllT.Selected = $Cfg.Link
    $lblFHint.Text = if ($Cfg.Link) { 'Click a filter to apply it to ALL displays.' }
                     else { "Click a filter to apply it to Display $($St.Sel + 1)  ($($Names[$Scr[$St.Sel].DeviceName]))." }
    for ($i = 0; $i -lt $DispBtns.Count; $i++) { $DispBtns[$i].Selected = ($i -eq $St.Sel) }
    $tglLink.SetSilently($Cfg.Link)
}

# ================= FINE TUNE PAGE =================
$pL = New-Card $pageTune 0 0 284 630 'Top, Bottom, Left'
$pR = New-Card $pageTune 872 0 284 630 'Top, Bottom, Right'
$pM = New-Card $pageTune 296 0 564 630 'Top, Bottom, Left, Right'

# --- left: displays + my preset
[void](New-Label $pL 'DISPLAYS' 18 16 200 20 $fSec $cAccent)
$DispBtns = @()
$yy = 42
for ($i = 0; $i -lt $Scr.Count; $i++) {
    $sc = $Scr[$i]
    $b = New-Btn $pL "$($i + 1)   $($Names[$sc.DeviceName])" 16 $yy 252 52 $false $null ([string][char]0xE7F4)
    $b.SubText = "$($sc.Bounds.Width) x $($sc.Bounds.Height)" + $(if ($sc.Primary) { '   -   Primary' } else { '' })
    $b.Tag = $i; $b.Radius = 12
    $b.add_Click({ Select-Display ([int]$this.Tag) })
    $DispBtns += $b; $yy += 58
}
$btnIdent = New-Btn $pL 'Identify' 16 ($yy + 2) 123 34
$btnCopy  = New-Btn $pL 'Copy to all' 145 ($yy + 2) 123 34
$tips.SetToolTip($btnIdent, 'Shows a big number on each screen')
$tips.SetToolTip($btnCopy, 'Copies this display settings to every display')
$tglLink = New-Toggle $pL 'Edit all displays together' 16 ($yy + 46) 252 28
$yy += 88
[void](New-Line $pL 16 $yy 252)
[void](New-Label $pL 'MY PRESET' 18 ($yy + 12) 200 20 $fSec $cAccent)
$lblEdit = New-Label $pL '' 18 ($yy + 36) 250 42 $fBody $cText
$btnSaveNew = New-Btn $pL 'Save as new preset' 16 ($yy + 82) 252 38 $true $null ([string][char]0xE74E)
$btnUpdate  = New-Btn $pL 'Update this preset' 16 ($yy + 126) 252 36 $false $null ([string][char]0xE72C)
$btnRenL    = New-Btn $pL 'Rename' 16 ($yy + 168) 123 34 $false $null ([string][char]0xE8AC)
$btnDelL    = New-Btn $pL 'Delete' 145 ($yy + 168) 123 34 $false $null ([string][char]0xE74D)
[void](New-Label $pL 'Pick any filter, change the sliders, then save it as your own preset.' 18 ($yy + 210) 250 40 $fSmall $cDim)

# --- middle: sliders
[void](New-Label $pM 'PICTURE' 20 16 90 20 $fSec $cAccent)
[void](New-Label $pM 'software filter - drag, scroll, use arrow keys or type a value. Double-click a slider to reset it.' 96 18 450 18 $fSmall $cDim 'Top, Left, Right')

$SliderTb = @{}; $ValBox = @{}
function Format-Val($k, $v) { $sp = $SpecByK[$k]; if ($sp.Div -gt 1) { ('{0:0.00}' -f ($v / $sp.Div)).Replace(',', '.') } else { "$v" } }
function Commit-Box($tb) {
    $k = $tb.Tag; $sp = $SpecByK[$k]; $n = 0.0
    $txt = $tb.Text.Replace(',', '.').Replace('%', '').Trim()
    if ([double]::TryParse($txt, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) {
        $SliderTb[$k].Value = [int][Math]::Round($n * $sp.Div)
    }
    $tb.Text = Format-Val $k $SliderTb[$k].Value
}
$y = 46
foreach ($sp in $Specs) {
    $lb = New-Label $pM $sp.L 20 ($y + 9) 110 22 $fBody $cText
    $tips.SetToolTip($lb, $sp.Tip)
    $sl = New-Object AmoSlider
    $sl.Minimum = $sp.Min; $sl.Maximum = $sp.Max; $sl.DefaultValue = $sp.Def; $sl.SetSilently($sp.Def); $sl.Tag = $sp.K
    Place $sl 126 $y 330 38 $pM 'Top, Left, Right'
    $tips.SetToolTip($sl, $sp.Tip + '  (double-click to reset)')
    $vb = New-Card $pM 468 ($y + 4) 76 30 'Top, Right' $cPanel2 10
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.BorderStyle = 'None'; $tb.BackColor = $cPanel2; $tb.ForeColor = $cText; $tb.Font = $fValue; $tb.TextAlign = 'Center'; $tb.Tag = $sp.K
    $tb.Text = Format-Val $sp.K $sp.Def
    Place $tb 6 6 64 20 $vb
    $tb.add_KeyDown({ param($s, $e)
        if ($e.KeyCode -eq 'Enter') { Commit-Box $s; $e.SuppressKeyPress = $true }
        elseif ($e.KeyCode -eq 'Up') { $SliderTb[$s.Tag].Value += 1; $e.SuppressKeyPress = $true }
        elseif ($e.KeyCode -eq 'Down') { $SliderTb[$s.Tag].Value -= 1; $e.SuppressKeyPress = $true }
    })
    $tb.add_Leave({ Commit-Box $this })
    $sl.add_ValueChanged({
        $k = $this.Tag
        $ValBox[$k].Text = Format-Val $k $this.Value
        if (-not $St.Busy) { Set-Param $k $this.Value }
    })
    $SliderTb[$sp.K] = $sl; $ValBox[$sp.K] = $tb
    $y += 42
}

[void](New-Line $pM 20 474 524 'Top, Left, Right')
[void](New-Label $pM 'MONITOR HARDWARE' 20 486 170 20 $fSec $cAccent)
[void](New-Label $pM 'real backlight via DDC/CI' 182 488 300 18 $fSmall $cDim)
$HwTb = @(); $HwBox = @()
$hwNames = @('Backlight', 'Monitor contrast')
for ($k = 0; $k -lt 2; $k++) {
    $hy = 512 + $k * 42
    [void](New-Label $pM $hwNames[$k] 20 ($hy + 9) 110 22 $fBody $cText)
    $sl = New-Object AmoSlider; $sl.Minimum = 0; $sl.Maximum = 100; $sl.DefaultValue = 50; $sl.Tag = $k; $sl.Enabled = $false
    Place $sl 126 $hy 330 38 $pM 'Top, Left, Right'
    $vb = New-Card $pM 468 ($hy + 4) 76 30 'Top, Right' $cPanel2 10
    $lbv = New-Label $vb '-' 0 0 76 30 $fValue $cText; $lbv.TextAlign = 'MiddleCenter'
    $sl.add_ValueChanged({
        $k2 = [int]$this.Tag
        $HwBox[$k2].Text = "$($this.Value)"
        if (-not $St.Busy) { $St.HwPending[$k2] = $this.Value; $tHw.Stop(); $tHw.Start() }
    })
    $HwTb += $sl; $HwBox += $lbv
}
$lblHw = New-Label $pM '' 20 596 524 30 $fSmall $cDim 'Top, Left, Right'

# --- right: curve, actions, options
[void](New-Label $pR 'TONE CURVE' 18 16 200 20 $fSec $cAccent)
$pic = New-Object System.Windows.Forms.PictureBox; $pic.BackColor = $cPanel
Place $pic 16 42 252 170 $pR
$pic.add_Paint({ param($sender, $e)
    $g = $e.Graphics; $g.SmoothingMode = 'AntiAlias'
    $w = $sender.ClientSize.Width; $h = $sender.ClientSize.Height
    $g.Clear($cPanel)
    $path = [AmoDraw]::Round((New-Object System.Drawing.RectangleF(0.5, 0.5, ($w - 1.5), ($h - 1.5))), (Px 12))
    $fb = New-Object System.Drawing.SolidBrush $cPanel2; $g.FillPath($fb, $path); $fb.Dispose()
    $g.SetClip($path)
    $grid = New-Object System.Drawing.Pen $cBorder
    for ($q = 1; $q -lt 4; $q++) {
        $g.DrawLine($grid, [int]($w * $q / 4), 0, [int]($w * $q / 4), $h)
        $g.DrawLine($grid, 0, [int]($h * $q / 4), $w, [int]($h * $q / 4))
    }
    $grid.Dispose()
    $dp = New-Object System.Drawing.Pen $cDim; $dp.DashStyle = 'Dash'; $g.DrawLine($dp, 0, $h, $w, 0); $dp.Dispose()
    $v = if ($St.Off) { New-Vals } else { Get-Vals $Scr[$St.Sel].DeviceName }
    $cv = Get-Curve $v
    $cols = @([System.Drawing.Color]::FromArgb(255, 80, 95), [System.Drawing.Color]::FromArgb(80, 230, 120), [System.Drawing.Color]::FromArgb(70, 150, 255))
    for ($ch = 0; $ch -lt 3; $ch++) {
        $pts = New-Object 'System.Drawing.PointF[]' 52
        for ($j = 0; $j -lt 52; $j++) {
            $i = [int]($j * 255 / 51)
            $pts[$j] = New-Object System.Drawing.PointF(([float]($i / 255.0 * ($w - 1))), ([float](($h - 1) - $cv[$ch * 256 + $i] * ($h - 1))))
        }
        $pen = New-Object System.Drawing.Pen($cols[$ch], [float](2 * $UiScale)); $g.DrawLines($pen, $pts); $pen.Dispose()
    }
    $g.ResetClip(); $path.Dispose()
})
$btnCompare  = New-Btn $pR 'Hold to compare' 16 222 252 36 $false $null ([string][char]0xE890)
$btnPower    = New-Btn $pR 'Effects: ON' 16 264 252 36 $true $null ([string][char]0xE7E8)
$btnResetOne = New-Btn $pR 'Reset display' 16 306 123 34
$btnResetAll = New-Btn $pR 'Reset all' 145 306 123 34
[void](New-Label $pR 'OPTIONS' 18 352 200 20 $fSec $cAccent)
$tglStart = New-Toggle $pR 'Apply permanently' 16 376 252 28
$tips.SetToolTip($tglStart, 'Starts with Windows and re-applies your look after restart, sleep and games')
$tglLock  = New-Toggle $pR 'Keep applied (games / sleep)' 16 408 252 28
$tglTray  = New-Toggle $pR 'Close button hides to tray' 16 440 252 28
$tips.SetToolTip($tglLock, 'Re-applies your look every 3 seconds, in case a game or sleep resets it')
$btnUnlock = New-Btn $pR 'Unlock stronger effects' 16 476 252 34 $false $null ([string][char]0xE785)
[void](New-Label $pR 'HOTKEYS' 18 520 200 20 $fSec $cAccent)
$keysTxt = "Ctrl+Alt+PgUp/PgDn  Brightness`nCtrl+Alt+Home  Effects on/off`nCtrl+Alt+End   Next filter`nCtrl+Alt+Ins   Open window`nF11            Full screen"
[void](New-Label $pR $keysTxt 18 542 260 84 $fMono $cDim)

# ================= ABOUT CREATOR PAGE =================
$cardA = New-Card $pageAbout 0 0 1156 630 'Top, Bottom, Left, Right'
$abIn = New-Object System.Windows.Forms.Panel; $abIn.BackColor = $cPanel
Place $abIn 128 24 900 590 $cardA
$cardA.add_Resize({
    $abIn.Left = [Math]::Max((Px 16), [int](($cardA.Width - $abIn.Width) / 2))
    $abIn.Top = [Math]::Max((Px 16), [int](($cardA.Height - $abIn.Height) / 2))
})
$av = New-Object AmoAvatar; $av.Initials = 'RYD'
Place $av 0 6 184 184 $abIn
[void](New-Label $abIn 'CREATOR' 214 14 300 20 $fSec $cAccent)
[void](New-Label $abIn $Creator.Name 210 36 690 50 $fBig ([System.Drawing.Color]::White))
[void](New-Label $abIn $Creator.Role 214 90 680 22 $fBody $cCyan)
[void](New-Label $abIn $Creator.Location 214 114 680 20 $fSmall $cDim)
[void](New-Label $abIn $Creator.Bio 214 140 680 44 $fBody $cText)

[void](New-Label $abIn 'FOLLOW ME' 0 214 300 20 $fSec $cAccent)
$bInsta = New-Btn $abIn 'Instagram   @svg_riyaaad' 0 242 290 50 $true
$bLinked = New-Btn $abIn 'LinkedIn   in/riyad200' 305 242 290 50 $true
$bWeb = New-Btn $abIn 'Website   10vir.me' 610 242 290 50 $false $null ([string][char]0xE774)
foreach ($pb in @($bInsta, $bLinked, $bWeb)) { $pb.Font = $fBold; $pb.Radius = 14 }
$bInsta.Tag = $Creator.Instagram; $bLinked.Tag = $Creator.LinkedIn; $bWeb.Tag = $Creator.Website
foreach ($pb in @($bInsta, $bLinked, $bWeb)) { $tips.SetToolTip($pb, $pb.Tag); $pb.add_Click({ Open-Url $this.Tag }) }

[void](New-Line $abIn 0 316 900)
[void](New-Label $abIn 'ABOUT THIS APP' 0 332 300 20 $fSec $cAccent)
$appTxt = "$AppName  v$AppVersion  -  designed and developed by $($Creator.Name).`n" +
          "Makes any monitor look closer to a Super AMOLED screen: deeper blacks, more contrast, colour tone and brightness, " +
          "with $($Filters.Count) built-in filters, your own presets, hotkeys and real monitor backlight control."
[void](New-Label $abIn $appTxt 0 358 900 64 $fBody $cText)
[void](New-Label $abIn 'LICENSE' 0 432 300 20 $fSec $cAccent)
[void](New-Label $abIn $LicenseText 0 456 900 44 $fBody $cDim)
[void](New-Label $abIn $Copyright 0 528 600 24 $fBold ([System.Drawing.Color]::White))
$btnVisit = New-Btn $abIn 'Visit 10vir.me' 740 518 160 40 $true
$btnVisit.add_Click({ Open-Url $Creator.Website })

function Load-Avatar {
    try {
        if (Test-Path $AvatarFile) {
            $bytes = [IO.File]::ReadAllBytes($AvatarFile)
            $script:AvatarStream = New-Object IO.MemoryStream(, $bytes)
            $av.Picture = [System.Drawing.Image]::FromStream($script:AvatarStream)
        }
    } catch {}
}
function Fetch-Avatar {
    try {
        if ((Test-Path $AvatarFile) -and ((Get-Date) - (Get-Item $AvatarFile).LastWriteTime).TotalDays -lt 7) { return }
        if (-not (Test-Path $CfgDir)) { New-Item -ItemType Directory -Path $CfgDir | Out-Null }
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $wc.Headers.Add('User-Agent', 'Mozilla/5.0 AmoledDisplayTuner')
        $wc.add_DownloadFileCompleted({ param($s, $ev)
            if (-not $ev.Error -and -not $ev.Cancelled) {
                try { Move-Item -LiteralPath $AvatarTmp -Destination $AvatarFile -Force; Load-Avatar } catch {}
            }
            $s.Dispose()
        })
        $wc.DownloadFileAsync((New-Object Uri $Creator.Photo), $AvatarTmp)
    } catch {}
}

# ---------- OSD ----------
$osd = New-Object OsdForm
$osd.FormBorderStyle = 'None'; $osd.ShowInTaskbar = $false; $osd.TopMost = $true; $osd.StartPosition = 'Manual'
$osd.BackColor = $cAccentDark; $osd.AutoScaleMode = 'None'; $osd.Size = New-Object System.Drawing.Size((Px 320), (Px 60))
$osdLbl = New-Object System.Windows.Forms.Label; $osdLbl.Dock = 'Fill'; $osdLbl.TextAlign = 'MiddleCenter'
$osdLbl.Font = $fTitle; $osdLbl.ForeColor = [System.Drawing.Color]::White; $osd.Controls.Add($osdLbl)
$osd.add_Load({ $osd.Region = New-Object System.Drawing.Region([AmoDraw]::Round((New-Object System.Drawing.RectangleF(0, 0, $osd.Width, $osd.Height)), (Px 18))) })
$tOsd = New-Object System.Windows.Forms.Timer; $tOsd.Interval = 1300
$tOsd.add_Tick({ $tOsd.Stop(); $osd.Hide() })
function Show-Osd($text) {
    $osdLbl.Text = $text
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $osd.Location = New-Object System.Drawing.Point(($wa.X + [int](($wa.Width - $osd.Width) / 2)), ($wa.Y + (Px 60)))
    $osd.Show(); $tOsd.Stop(); $tOsd.Start()
}

# ---------- timers ----------
$tApply = New-Object System.Windows.Forms.Timer; $tApply.Interval = 30
$tSave  = New-Object System.Windows.Forms.Timer; $tSave.Interval = 800
$tHw    = New-Object System.Windows.Forms.Timer; $tHw.Interval = 250
$tLock  = New-Object System.Windows.Forms.Timer; $tLock.Interval = 3000
$tId    = New-Object System.Windows.Forms.Timer; $tId.Interval = 2000
$tBoot  = New-Object System.Windows.Forms.Timer; $tBoot.Interval = 2500; $St.BootN = 0
$tPage  = New-Object System.Windows.Forms.Timer; $tPage.Interval = 15
$tFade  = New-Object System.Windows.Forms.Timer; $tFade.Interval = 15

$tApply.add_Tick({
    $tApply.Stop()
    $ok = $true
    foreach ($s in (Targets)) { if (-not (Apply-Screen $s)) { $ok = $false } }
    if ($ok) { Set-Status 'Applied live' 'good' } else { Show-Result $false }
    $pic.Invalidate()
    $tSave.Stop(); $tSave.Start()
})
$tSave.add_Tick({ $tSave.Stop(); Save-Config })
$tHw.add_Tick({
    $tHw.Stop()
    $fail = $false
    foreach ($s in (Targets)) {
        $c = Center $s
        foreach ($k in @($St.HwPending.Keys)) {
            try { if (-not [AmoNative]::SetVcp($c[0], $c[1], [int]$k, [int]$St.HwPending[$k])) { $fail = $true } } catch { $fail = $true }
        }
    }
    $St.HwPending.Clear()
    if ($fail) { Set-Status 'Some monitors did not accept the hardware change (DDC/CI off?)' 'warn' } else { Set-Status 'Monitor hardware updated' 'good' }
})
$tLock.add_Tick({ if (-not $St.Holding) { foreach ($s in $Scr) { [void](Apply-Screen $s) } } })
$tId.add_Tick({ $tId.Stop(); foreach ($f in $St.IdForms) { $f.Close(); $f.Dispose() }; $St.IdForms = @() })
$tBoot.add_Tick({
    foreach ($s in $Scr) { [void](Apply-Screen $s) }
    $St.BootN++
    if ($St.BootN -ge 6) { $tBoot.Stop() } else { $tBoot.Interval = 5000 * $St.BootN }
})
$tPage.add_Tick({
    $p = $St.AnimPage; $target = Px 12
    if (-not $p) { $tPage.Stop(); return }
    $nl = $target + [int](($p.Left - $target) * 0.72)
    if ([Math]::Abs($nl - $target) -le 1) { $nl = $target; $tPage.Stop() }
    $p.Left = $nl
})
$tFade.add_Tick({ $o = $form.Opacity + 0.08; if ($o -ge 1) { $o = 1; $tFade.Stop() }; $form.Opacity = $o })

# ======================= LOGIC =======================
function Show-Page($name) {
    if ($St.Page -eq $name) { return }
    $new = $Pages[$name]; $old = if ($St.Page) { $Pages[$St.Page] } else { $null }
    $St.Page = $name
    foreach ($k in $NavBtns.Keys) { $NavBtns[$k].Selected = ($k -eq $name) }
    Layout-Pages
    $new.Left = Px 60; $new.Visible = $true; $new.BringToFront()
    if ($old) { $old.Visible = $false }
    $St.AnimPage = $new; $tPage.Start()
    if ($name -eq 'Filters') { Update-TargetBtns; Update-Tiles }
    if ($name -eq 'Tune') { Load-UI }
}
function Toggle-Fullscreen {
    if (-not $St.Full) {
        $St.PrevState = $form.WindowState; $form.WindowState = 'Normal'; $St.PrevBounds = $form.Bounds
        $form.FormBorderStyle = 'None'
        $form.Bounds = [System.Windows.Forms.Screen]::FromControl($form).Bounds
        $St.Full = $true; Set-Status 'Full screen - press F11 or Esc to exit' 'info'
    } else {
        $form.FormBorderStyle = 'Sizable'
        $form.Bounds = $St.PrevBounds; $form.WindowState = $St.PrevState
        $St.Full = $false; [AmoNative]::StyleWindow($form.Handle)
    }
}
function Set-Link($on) {
    $Cfg.Link = [bool]$on; Save-Config; Update-TargetBtns
    if ($Cfg.Link) { Set-Status 'All displays: changes go to every display' 'info' } else { Set-Status "Editing Display $($St.Sel + 1) only" 'info' }
}
function Select-Display($i) {
    $St.Sel = $i
    Load-UI; Load-Hw; Update-TargetBtns; Update-Tiles; Update-PresetUI
}
function Current-Name { $Cfg.Active[$Scr[$St.Sel].DeviceName] }
function Set-Param($k, $val) {
    foreach ($s in (Targets)) { (Get-Vals $s.DeviceName)[$k] = [int]$val; $Cfg.Modified[$s.DeviceName] = $true }
    if (-not $St.EditUiPending) { $St.EditUiPending = $true; Update-PresetUI; $St.EditUiPending = $false }
    $tApply.Stop(); $tApply.Start()
}
function Load-UI {
    $St.Busy = $true
    $v = Get-Vals $Scr[$St.Sel].DeviceName
    foreach ($sp in $Specs) { $SliderTb[$sp.K].Value = [int]$v[$sp.K] }
    $St.Busy = $false
    $pic.Invalidate()
}
function Load-Hw {
    $c = Center $Scr[$St.Sel]
    $St.Busy = $true; $any = $false
    for ($k = 0; $k -lt 2; $k++) {
        $r = $null
        try { $r = [AmoNative]::GetVcp($c[0], $c[1], $k) } catch {}
        $sl = $HwTb[$k]
        if ($r) {
            $sl.Minimum = $r[0]; $sl.Maximum = [Math]::Max($r[0] + 1, $r[2]); $sl.Value = $r[1]
            $HwBox[$k].Text = "$($sl.Value)"; $sl.Enabled = $true; $any = $true
        } else { $sl.Enabled = $false; $HwBox[$k].Text = '-' }
    }
    $St.Busy = $false
    if ($any) { $lblHw.Text = "Changes the monitor's real backlight, like its own buttons. Best way to make it truly brighter."; $lblHw.ForeColor = $cDim }
    else { $lblHw.Text = "Not available on this monitor. Turn ON 'DDC/CI' in the monitor's own menu, then select the display again."; $lblHw.ForeColor = $cWarn }
}
function Update-PresetUI {
    $dev = $Scr[$St.Sel].DeviceName
    $name = $Cfg.Active[$dev]; if (-not $name) { $name = 'Normal' }
    $mod = [bool]$Cfg.Modified[$dev]
    $mine = $Cfg.Custom.ContainsKey($name)
    $lblEdit.Text = "Based on: $name" + $(if ($mod) { "`n(edited - not saved yet)" } elseif ($mine) { "`n(your preset)" } else { '' })
    $lblEdit.ForeColor = if ($mod) { $cWarn } elseif ($mine) { $cCyan } else { $cText }
    $btnUpdate.Enabled = $mine -and $mod
    $btnUpdate.Text = if ($mine) { "Update '$name'" } else { 'Update this preset' }
    $btnRenL.Enabled = $mine; $btnDelL.Enabled = $mine
    $lblSelTitle.Text = "Selected: $name" + $(if ($mod) { '  (edited)' } else { '' })
    $lblSelSub.Text = if ($mine) { 'Your own preset. Customise it, rename it or delete it.' } else { 'Built-in filter. Customise it, then save it as your own preset.' }
    $bRen.Enabled = $mine; $bDel.Enabled = $mine
}
function Refresh-Presets {
    $St.PresetList = @()
    foreach ($n in $Builtin.Keys) { $St.PresetList += $n }
    foreach ($n in ($Cfg.Custom.Keys | Sort-Object)) { $St.PresetList += $n }
    Build-Tiles; Update-PresetUI
}
function Apply-Preset($name, $all = $false) {
    if (-not $name) { return }
    $tg = if ($all) { $Scr } else { Targets }
    foreach ($s in $tg) { $Cfg.Displays[$s.DeviceName] = Preset-Vals $name; $Cfg.Active[$s.DeviceName] = $name; $Cfg.Modified[$s.DeviceName] = $false }
    Load-UI
    $ok = $true; foreach ($s in $tg) { if (-not (Apply-Screen $s)) { $ok = $false } }
    if ($ok) { Set-Status "Applied: $name" 'good' } else { Show-Result $false }
    $idx = [array]::IndexOf($St.PresetList, $name); if ($idx -ge 0) { $St.PresetIdx = $idx }
    Update-Tiles; Update-PresetUI; Save-Config
}
function Save-NewPreset {
    $base = Current-Name; if (-not $base) { $base = 'My Look' }
    $suggest = if ($Cfg.Custom.ContainsKey($base)) { "$base 2" } else { "$base (mine)" }
    $name = Ask-Text 'Save as my preset' 'Give your preset a name:' $suggest
    if (-not $name) { return }
    if ($Builtin.Contains($name)) { $name = "$name (mine)" }
    if ($Cfg.Custom.ContainsKey($name)) {
        if ([System.Windows.Forms.MessageBox]::Show("'$name' already exists. Replace it?", 'Save preset', 'YesNo') -ne 'Yes') { return }
    }
    $vals = Copy-Vals (Get-Vals $Scr[$St.Sel].DeviceName)
    $Cfg.Custom[$name] = $vals
    foreach ($s in (Targets)) { $Cfg.Active[$s.DeviceName] = $name; $Cfg.Modified[$s.DeviceName] = $false }
    Save-Config; Refresh-Presets
    Set-Status "Saved to My presets: $name" 'good'
}
function Update-Preset {
    $name = Current-Name
    if (-not $Cfg.Custom.ContainsKey($name)) { return }
    $Cfg.Custom[$name] = Copy-Vals (Get-Vals $Scr[$St.Sel].DeviceName)
    foreach ($s in (Targets)) { $Cfg.Modified[$s.DeviceName] = $false }
    Save-Config; Refresh-Presets; Set-Status "Updated: $name" 'good'
}
function Rename-Preset($old) {
    if (-not $old -or -not $Cfg.Custom.ContainsKey($old)) { Set-Status 'Only your own presets can be renamed' 'warn'; return }
    $new = Ask-Text 'Rename preset' 'New name:' $old
    if (-not $new -or $new -eq $old) { return }
    if ($Builtin.Contains($new) -or $Cfg.Custom.ContainsKey($new)) { Set-Status 'That name is already used' 'warn'; return }
    $Cfg.Custom[$new] = $Cfg.Custom[$old]; $Cfg.Custom.Remove($old)
    foreach ($k in @($Cfg.Active.Keys)) { if ($Cfg.Active[$k] -eq $old) { $Cfg.Active[$k] = $new } }
    Save-Config; Refresh-Presets; Set-Status "Renamed to: $new" 'good'
}
function Delete-Preset($name) {
    if (-not $name -or -not $Cfg.Custom.ContainsKey($name)) { Set-Status 'Built-in filters cannot be deleted' 'warn'; return }
    if ([System.Windows.Forms.MessageBox]::Show("Delete your preset '$name'?", 'Delete preset', 'YesNo', 'Warning') -ne 'Yes') { return }
    $Cfg.Custom.Remove($name)
    foreach ($k in @($Cfg.Active.Keys)) { if ($Cfg.Active[$k] -eq $name) { $Cfg.Modified[$k] = $true } }
    Save-Config; Refresh-Presets; Set-Status "Deleted: $name" 'info'
}
function Update-Power {
    $btnPower.Accent = -not $St.Off
    $btnPower.Text = if ($St.Off) { 'Effects: OFF  (click to turn on)' } else { 'Effects: ON' }
    $miPower.Text = if ($St.Off) { 'Turn effects ON' } else { 'Turn effects OFF' }
}
function Toggle-Power { $St.Off = -not $St.Off; Update-Power; Apply-All; $pic.Invalidate(); if ($St.Off) { 'Effects OFF' } else { 'Effects ON' } }
function Step-Bright($d) {
    foreach ($s in $Scr) { $v = Get-Vals $s.DeviceName; $v.Brightness = [Math]::Min(150, [Math]::Max(20, [int]$v.Brightness + $d)) }
    Load-UI; Apply-All; $tSave.Stop(); $tSave.Start()
    "Brightness  $((Get-Vals $Scr[$St.Sel].DeviceName).Brightness)%"
}
function Next-Preset {
    if ($St.PresetList.Count -eq 0) { return 'No filters' }
    $St.PresetIdx = ($St.PresetIdx + 1) % $St.PresetList.Count
    $n = $St.PresetList[$St.PresetIdx]; Apply-Preset $n $true; $n
}
function Show-Main { $form.Opacity = 1; $form.Show(); if ($form.WindowState -eq 'Minimized') { $form.WindowState = 'Normal' }; $form.Activate() }
function Show-Identify {
    foreach ($f in $St.IdForms) { $f.Close() }
    $list = @()
    for ($i = 0; $i -lt $Scr.Count; $i++) {
        $s = $Scr[$i]; $sz = Px 220
        $f = New-Object OsdForm
        $f.FormBorderStyle = 'None'; $f.StartPosition = 'Manual'; $f.ShowInTaskbar = $false; $f.TopMost = $true
        $f.BackColor = $cAccentDark; $f.AutoScaleMode = 'None'
        $f.Bounds = New-Object System.Drawing.Rectangle(($s.Bounds.X + [int](($s.Bounds.Width - $sz) / 2)), ($s.Bounds.Y + [int](($s.Bounds.Height - $sz) / 2)), $sz, $sz)
        $f.Region = New-Object System.Drawing.Region([AmoDraw]::Round((New-Object System.Drawing.RectangleF(0, 0, $sz, $sz)), (Px 40)))
        $l = New-Object System.Windows.Forms.Label; $l.Dock = 'Fill'; $l.TextAlign = 'MiddleCenter'
        $l.Font = New-Object System.Drawing.Font('Segoe UI', 72, [System.Drawing.FontStyle]::Bold); $l.ForeColor = [System.Drawing.Color]::White
        $l.Text = "$($i + 1)"; $f.Controls.Add($l); $f.Show()
        $list += $f
    }
    $St.IdForms = $list; $tId.Stop(); $tId.Start()
}

# ---------- events ----------
$tglLink.add_CheckedChanged({ if (-not $St.Busy) { Set-Link $tglLink.Checked } })
$btnIdent.add_Click({ Show-Identify })
$btnCopy.add_Click({
    $dev = $Scr[$St.Sel].DeviceName
    $src = Copy-Vals (Get-Vals $dev); $act = $Cfg.Active[$dev]; $mod = $Cfg.Modified[$dev]
    foreach ($s in $Scr) { $Cfg.Displays[$s.DeviceName] = Copy-Vals $src; $Cfg.Active[$s.DeviceName] = $act; $Cfg.Modified[$s.DeviceName] = $mod }
    Apply-All; Save-Config; Set-Status 'Copied to all displays' 'good'
})
$btnSaveNew.add_Click({ Save-NewPreset })
$btnUpdate.add_Click({ Update-Preset })
$btnRenL.add_Click({ Rename-Preset (Current-Name) })
$btnDelL.add_Click({ Delete-Preset (Current-Name) })
$btnCompare.add_MouseDown({ $St.Holding = $true; Apply-All; Set-Status 'Showing ORIGINAL - release to go back' 'warn' })
$btnCompare.add_MouseUp({ $St.Holding = $false; Apply-All; Set-Status 'Your look is back' 'good' })
$btnPower.add_Click({ [void](Toggle-Power) })
$btnResetOne.add_Click({
    foreach ($s in (Targets)) { $Cfg.Displays[$s.DeviceName] = New-Vals; $Cfg.Active[$s.DeviceName] = 'Normal'; $Cfg.Modified[$s.DeviceName] = $false }
    Load-UI; Apply-All; Save-Config; Update-PresetUI; Set-Status 'Display reset to normal' 'info'
})
$btnResetAll.add_Click({
    foreach ($s in $Scr) { $Cfg.Displays[$s.DeviceName] = New-Vals; $Cfg.Active[$s.DeviceName] = 'Normal'; $Cfg.Modified[$s.DeviceName] = $false }
    Load-UI; Apply-All; Save-Config; Update-PresetUI; Set-Status 'All displays reset to normal' 'info'
})
$tglStart.add_CheckedChanged({
    if ($St.Busy) { return }
    Set-Permanent $tglStart.Checked
})
# ---------- permanent apply ----------
function Test-Permanent {
    try { $v = (Get-ItemProperty -Path $RunKey -Name $RunName -ErrorAction Stop).$RunName; return [bool]$v } catch { return $false }
}
function Install-Permanent {
    if (-not (Test-Path $CfgDir)) { New-Item -ItemType Directory -Path $CfgDir | Out-Null }
    # keep a private copy so moving or deleting the original .bat does not break it
    if ($env:AMO_SELF -and (Test-Path $env:AMO_SELF) -and ($env:AMO_SELF -ne $PermCopy)) { Copy-Item -LiteralPath $env:AMO_SELF -Destination $PermCopy -Force }
    if (-not (Test-Path $PermCopy)) { throw 'App copy missing' }
    if (-not (Test-Path $RunKey)) { New-Item -Path $RunKey -Force | Out-Null }
    Set-ItemProperty -Path $RunKey -Name $RunName -Value ("cmd.exe /c `"`"$PermCopy`" autoapply`"")
    if (Test-Path $Startup) { Remove-Item $Startup -Force }   # old startup method, avoid double start
}
function Uninstall-Permanent {
    try { Remove-ItemProperty -Path $RunKey -Name $RunName -ErrorAction SilentlyContinue } catch {}
    if (Test-Path $Startup) { Remove-Item $Startup -Force }
}
function Update-PermUI {
    $St.Busy = $true
    $tglStart.SetSilently($Cfg.Permanent)
    $tglLock.SetSilently($Cfg.Lock)
    $St.Busy = $false
    if ($Cfg.Permanent) { $bPerm.Text = 'Permanent: ON'; $bPerm.Glyph = [string][char]0xE73E }
    else { $bPerm.Text = 'Apply permanently'; $bPerm.Glyph = [string][char]0xE718 }

    $miPerm.Checked = $Cfg.Permanent
    $bPerm.Invalidate()
}
function Set-Permanent($on) {
    try {
        if ($on) {
            if ($St.Off) { $St.Off = $false; Update-Power }
            Install-Permanent
            $Cfg.Permanent = $true; $Cfg.Lock = $true; $tLock.Start()
            Apply-All; Save-Config
            Set-Status 'Applied permanently - stays after restart, sleep and games' 'good'
        } else {
            Uninstall-Permanent
            $Cfg.Permanent = $false; Save-Config
            Set-Status 'Permanent apply turned off - look resets after restart' 'info'
        }
    } catch {
        Set-Status "Could not apply permanently: $($_.Exception.Message)" 'bad'
        $Cfg.Permanent = Test-Permanent
    }
    Update-PermUI
}

$tglLock.add_CheckedChanged({
    if ($St.Busy) { return }
    $Cfg.Lock = $tglLock.Checked; Save-Config
    if ($Cfg.Lock) { $tLock.Start() } else { $tLock.Stop() }
})
$tglTray.add_CheckedChanged({ if ($St.Busy) { return }; $Cfg.Tray = $tglTray.Checked; Save-Config })
$btnUnlock.add_Click({
    $script = @'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ICM'
if (-not (Test-Path $k)) { New-Item -Path $k | Out-Null }
New-ItemProperty -Path $k -Name GdiIcmGammaRange -PropertyType DWord -Value 256 -Force | Out-Null
'@
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
    try {
        Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -EncodedCommand $enc"
        [System.Windows.Forms.MessageBox]::Show('Unlocked. Restart your PC so stronger settings are allowed.', $AppName) | Out-Null
    } catch { Set-Status 'Admin permission was cancelled' 'warn' }
})
$form.add_KeyDown({ param($s, $e)
    if ($e.KeyCode -eq 'F11') { Toggle-Fullscreen; $e.Handled = $true }
    elseif ($e.KeyCode -eq 'Escape' -and $St.Full) { Toggle-Fullscreen; $e.Handled = $true }
})

# ---------- tray ----------
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $appIcon; $tray.Text = "$AppName - by $($Creator.Short)"; $tray.Visible = $true
$menu = New-Object System.Windows.Forms.ContextMenuStrip; Style-Menu $menu
$miOpen = New-MenuItem 'Open'; $miOpen.add_Click({ Show-Main })
$miPresets = New-MenuItem 'Apply filter to all displays'
$miPower = New-MenuItem 'Turn effects OFF'; $miPower.add_Click({ [void](Toggle-Power) })
$miPerm = New-MenuItem 'Apply permanently'; $miPerm.add_Click({ Set-Permanent (-not $Cfg.Permanent) })
$miAbout = New-MenuItem 'About creator'; $miAbout.add_Click({ Show-Main; Show-Page 'About' })
$miExit = New-MenuItem 'Exit'; $miExit.add_Click({ $St.Exiting = $true; $form.Close() })
foreach ($it in @($miOpen, $miPresets, $miPower, $miPerm, $miAbout)) { [void]$menu.Items.Add($it) }
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)); [void]$menu.Items.Add($miExit)
$menu.add_Opening({
    $miPresets.DropDownItems.Clear()
    $groups = [ordered]@{}
    foreach ($c in $Categories) { $groups[$c] = @($Filters | Where-Object { $_.Cat -eq $c } | ForEach-Object { $_.Name }) }
    if ($Cfg.Custom.Count -gt 0) { $groups['My presets'] = @($Cfg.Custom.Keys | Sort-Object) }
    foreach ($c in $groups.Keys) {
        $sub = New-MenuItem $c
        foreach ($n in $groups[$c]) {
            $it = New-MenuItem $n; $it.Tag = $n
            $it.add_Click({ Apply-Preset $this.Tag $true })
            [void]$sub.DropDownItems.Add($it)
        }
        [void]$miPresets.DropDownItems.Add($sub)
    }
})
$tray.ContextMenuStrip = $menu
$tray.add_MouseClick({ param($sender, $e) if ($e.Button -eq 'Left') { Show-Main } })

# ---------- global hotkeys ----------
$hk = New-Object AmoHotkeys
$hkFail = 0
if (-not $hk.Register(1, 3, 0x21)) { $hkFail++ }
if (-not $hk.Register(2, 3, 0x22)) { $hkFail++ }
if (-not $hk.Register(3, 0x4003, 0x24)) { $hkFail++ }
if (-not $hk.Register(4, 0x4003, 0x23)) { $hkFail++ }
if (-not $hk.Register(5, 0x4003, 0x2D)) { $hkFail++ }
$hk.add_Pressed({ param($sender, $e)
    switch ($e.Id) {
        1 { Show-Osd (Step-Bright 5) }
        2 { Show-Osd (Step-Bright -5) }
        3 { Show-Osd (Toggle-Power) }
        4 { Show-Osd (Next-Preset) }
        5 { Show-Main }
    }
})

# ---------- window lifecycle ----------
$form.add_FormClosing({ param($sender, $e)
    if (-not $St.Exiting -and $Cfg.Tray -and $e.CloseReason -eq 'UserClosing') {
        $e.Cancel = $true; $form.Hide()
        if (-not $St.TipShown) {
            $tray.ShowBalloonTip(2500, $AppName, 'Still running in the tray. Hotkeys stay active. Right-click the icon to exit.', 'Info')
            $St.TipShown = $true
        }
        return
    }
    if (-not $St.Full) {
        $Cfg.WinMax = ($form.WindowState -eq 'Maximized')
        if ($form.WindowState -eq 'Normal') { $Cfg.WinW = $form.Width; $Cfg.WinH = $form.Height }
    }
})
$form.add_FormClosed({ Save-Config; $tray.Visible = $false; $tray.Dispose(); $hk.Dispose() })
$form.add_Shown({
    Layout-Pages
    Apply-All
    Fetch-Avatar
    if ($St.Tray) { $form.Hide(); $form.Opacity = 1; $tBoot.Start() }
    else {
        $tFade.Start()
        foreach ($u in $OpenOnLaunch) { if ($u) { Open-Url $u; Start-Sleep -Milliseconds 250 } }
        $form.Activate()
    }
})

# ---------- initial state ----------
$St.Busy = $true
$tglLink.SetSilently($Cfg.Link); $tglLock.SetSilently($Cfg.Lock); $tglTray.SetSilently($Cfg.Tray)
$St.Busy = $false
# older versions used the Startup folder - move them to the new permanent method
if ((Test-Path $Startup) -and -not $Cfg.Permanent) { $Cfg.Permanent = $true; $Cfg.Lock = $true }
if ($Cfg.Permanent) { try { Install-Permanent } catch {} } else { $Cfg.Permanent = Test-Permanent }
Update-PermUI
if ($Cfg.Lock) { $tLock.Start() }
if ($Cfg.WinW -gt 0) { $form.Size = New-Object System.Drawing.Size($Cfg.WinW, $Cfg.WinH) }
if ($Cfg.WinMax) { $form.WindowState = 'Maximized' }
Load-Avatar
Refresh-Presets
Update-Power
$primary = 0; for ($i = 0; $i -lt $Scr.Count; $i++) { if ($Scr[$i].Primary) { $primary = $i } }
Select-Display $primary
Show-Page 'Filters'
if ($hkFail -gt 0) { Set-Status "$hkFail hotkey(s) already used by another app" 'warn' }
else { Set-Status 'Ready - pick a filter, or fine-tune your own look' 'info' }
$form.Opacity = 0

[System.Windows.Forms.Application]::Run($form)

} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Something went wrong:`n`n$($_.Exception.Message)`n`nLine: $($_.InvocationInfo.ScriptLineNumber)`n`nRun the .bat with 'debug' to see more.", 'AMOLED Display Tuner') | Out-Null
}
