Add-Type -AssemblyName System.Drawing

$srcRoot = 'C:\Users\USER}\.cursor\projects\d-projects-developers-tx-proyectos-wss\assets'
$dstRoot = 'd:\projects-developers\tx\proyectos\wss\texi_passenger_app\assets\images\quick_trips'
New-Item -ItemType Directory -Force -Path $dstRoot | Out-Null

$code = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class QuickTripCutoutV2 {
  static bool IsGreenScreen(Color c) {
    return c.G > 80 && c.G > c.R + 22 && c.G > c.B + 22;
  }

  public static void Process(string src, string dst) {
    using (var srcImg = Image.FromFile(src))
    using (var bmp = new Bitmap(srcImg.Width, srcImg.Height, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(bmp)) {
        g.DrawImage(srcImg, 0, 0, srcImg.Width, srcImg.Height);
      }
      int w = bmp.Width, h = bmp.Height;
      int[] dx = { 1, -1, 0, 0 };
      int[] dy = { 0, 0, 1, -1 };

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          Color c = bmp.GetPixel(x, y);
          if (IsGreenScreen(c)) {
            bmp.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
          }
        }
      }

      for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
          Color c = bmp.GetPixel(x, y);
          if (c.A == 0) continue;
          bool nearClear = false;
          for (int i = 0; i < 4; i++) {
            if (bmp.GetPixel(x + dx[i], y + dy[i]).A == 0) { nearClear = true; break; }
          }
          if (!nearClear) continue;
          int over = c.G - Math.Max(c.R, c.B);
          if (over > 10) {
            int a = Math.Max(0, 255 - over * 7);
            int r = Math.Min(255, c.R + over / 2);
            int b = Math.Min(255, c.B + over / 2);
            int ng = Math.Max(0, c.G - over);
            bmp.SetPixel(x, y, Color.FromArgb(a, r, ng, b));
          }
        }
      }

      Rectangle bounds = ContentBounds(bmp);
      int pad = 18;
      bounds.X = Math.Max(0, bounds.X - pad);
      bounds.Y = Math.Max(0, bounds.Y - pad);
      bounds.Width = Math.Min(w - bounds.X, bounds.Width + pad * 2);
      bounds.Height = Math.Min(h - bounds.Y, bounds.Height + pad * 2);

      using (var cropped = bmp.Clone(bounds, PixelFormat.Format32bppArgb)) {
        cropped.Save(dst, ImageFormat.Png);
      }
    }
  }

  static Rectangle ContentBounds(Bitmap bmp) {
    int w = bmp.Width, h = bmp.Height;
    int minX = w, minY = h, maxX = 0, maxY = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (bmp.GetPixel(x, y).A < 12) continue;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < minX) return new Rectangle(0, 0, w, h);
    return Rectangle.FromLTRB(minX, minY, maxX + 1, maxY + 1);
  }
}
'@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

[QuickTripCutoutV2]::Process("$srcRoot\quick-trip-airport-key.png", "$dstRoot\airport.png")
[QuickTripCutoutV2]::Process("$srcRoot\quick-trip-work-key.png", "$dstRoot\work.png")
[QuickTripCutoutV2]::Process("$srcRoot\quick-trip-home-key.png", "$dstRoot\home.png")
[QuickTripCutoutV2]::Process("$srcRoot\quick-trip-favorite-key.png", "$dstRoot\favorite.png")
Get-ChildItem $dstRoot | ForEach-Object { $_.FullName + ' ' + $_.Length }
