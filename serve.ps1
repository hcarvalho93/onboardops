# Simple static file server for the OnboardOps single-page app.
# No Node/Python required - uses .NET's HttpListener (built into PowerShell).
param(
  [int]$Port = 8080
)

$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $root at $prefix (Ctrl+C to stop)"

$mime = @{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8'
  '.css'='text/css'; '.js'='application/javascript'; '.json'='application/json'
  '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.gif'='image/gif'
  '.svg'='image/svg+xml'; '.ico'='image/x-icon'; '.woff'='font/woff'; '.woff2'='font/woff2'; '.txt'='text/plain; charset=utf-8'; '.mjs'='application/javascript'; '.map'='application/json'; '.webp'='image/webp'; '.pdf'='application/pdf'
}

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    try {
      $path = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath)
      if ($path -eq '/' -or $path -eq '') { $path = '/index.html' }
      $full = Join-Path $root ($path.TrimStart('/'))
      $full = [System.IO.Path]::GetFullPath($full)
      if (-not $full.StartsWith((Get-Item $root).FullName)) {
        $res.StatusCode = 403; $res.Close(); continue
      }
      if (Test-Path $full -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($full).ToLower()
        $ct = $mime[$ext]; if (-not $ct) { $ct = 'application/octet-stream' }
        $bytes = [System.IO.File]::ReadAllBytes($full)
        $res.ContentType = $ct
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $res.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
        $res.OutputStream.Write($msg, 0, $msg.Length)
      }
    } catch {
      $res.StatusCode = 500
    } finally {
      $res.Close()
    }
  }
} finally {
  $listener.Stop()
}
