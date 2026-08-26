# Run this file as administrator for firewall permissions: screen_mirror.ps1

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$Port = 8080
$FPS = 8
$Width = 1280

# --- Find Local IP ---
$IP = $null
try {
    $IP = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.PrefixOrigin -ne "WellKnown"
        } |
        Select-Object -First 1 -ExpandProperty IPAddress
} catch {}

if (-not $IP) {
    $IP = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*"} |
        Select-Object -First 1 -ExpandProperty IPAddress)
}

if (-not $IP) {
    Write-Host "ERROR: Could not determine PC IP address." -ForegroundColor Red
    ipconfig
    Read-Host "Press ENTER to exit"
    exit
}

# --- TCP Listener ---
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)

try {
    $listener.Start()
} catch {
    Write-Host ""
    Write-Host "ERROR: Could not start port $Port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

# --- Add Firewall Rule ---
try {
    netsh advfirewall firewall add rule name="PC Screen Mirror 8080" dir=in action=allow protocol=TCP localport=8080 profile=private > $null 2>&1
} catch {}

# --- Styled Console Dashboard ---
Clear-Host

Write-Host ""
Write-Host "  ====================================================================" -ForegroundColor Cyan
Write-Host "       W I F I   S C R E E N   M I R R O R" -ForegroundColor White
Write-Host "       PC  >  ANDROID / MOBILE  >  LOCAL WIFI" -ForegroundColor DarkCyan
Write-Host "  ====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "       +-------------------+        +-------------------------+" -ForegroundColor DarkCyan
Write-Host "       |   WINDOWS PC      |        |     MOBILE DEVICE      |" -ForegroundColor DarkCyan
Write-Host "       |                   |        |                         |" -ForegroundColor DarkCyan
Write-Host "       |   SCREEN CAPTURE  | ====== |  BROWSER STREAM         |" -ForegroundColor Cyan
Write-Host "       |                   |  WiFi  |                         |" -ForegroundColor DarkCyan
Write-Host "       +-------------------+        +-------------------------+" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  CONNECTION" -ForegroundColor Cyan
Write-Host ""
Write-Host "      PHONE URL       " -NoNewline -ForegroundColor DarkGray
Write-Host "http://${IP}:${Port}" -ForegroundColor Green
Write-Host ""
Write-Host "      RESOLUTION      " -NoNewline -ForegroundColor DarkGray
Write-Host "$Width px wide" -ForegroundColor White
Write-Host "      FRAME RATE      " -NoNewline -ForegroundColor DarkGray
Write-Host "$FPS FPS" -ForegroundColor White
Write-Host "      NETWORK         " -NoNewline -ForegroundColor DarkGray
Write-Host "Local WiFi only" -ForegroundColor White
Write-Host "      PORT            " -NoNewline -ForegroundColor DarkGray
Write-Host "$Port" -ForegroundColor White
Write-Host ""
Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "      STATUS          " -NoNewline -ForegroundColor DarkGray
Write-Host "READY" -ForegroundColor Green
Write-Host ""
Write-Host "      Open the URL above on your Android phone." -ForegroundColor White
Write-Host "      Both devices must be connected to the SAME WiFi." -ForegroundColor Yellow
Write-Host ""
Write-Host "      Waiting for phone connection..." -ForegroundColor Cyan
Write-Host ""
Write-Host "  ====================================================================" -ForegroundColor Cyan
Write-Host "      CTRL+C  ->  STOP MIRROR" -ForegroundColor DarkGray
Write-Host "  ====================================================================" -ForegroundColor Cyan
Write-Host ""

# --- HTML Landing Page ---
$html = @"
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>PC Mirror</title>
    <style>
        html,body { margin:0; padding:0; background:#000; width:100%; height:100%; overflow:hidden; }
        img { width:100%; height:100%; object-fit:contain; }
    </style>
</head>
<body>
    <img src="/stream" />
</body>
</html>
"@

# --- Main Streaming Loop ---
try {
    while ($true) {
        $client = $null
        $network = $null

        try {
            $client = $listener.AcceptTcpClient()
            $network = $client.GetStream()

            $buffer = New-Object byte[] 8192
            $read = $network.Read($buffer, 0, $buffer.Length)

            if ($read -le 0) {
                if ($network) { $network.Close() }
                if ($client) { $client.Close() }
                continue
            }

            $request = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $read)

            if ($request -match "GET /stream") {
                $header = "HTTP/1.1 200 OK`r`n" +
                          "Content-Type: multipart/x-mixed-replace; boundary=frame`r`n" +
                          "Cache-Control: no-cache`r`n" +
                          "Connection: close`r`n`r`n"

                $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
                $network.Write($headerBytes, 0, $headerBytes.Length)
                $network.Flush()

                $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
                $targetHeight = [int](($screen.Height / $screen.Width) * $Width)

                while ($client.Connected) {
                    $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height)
                    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                    $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size)
                    $graphics.Dispose()

                    $newBitmap = New-Object System.Drawing.Bitmap($Width, $targetHeight)
                    $g2 = [System.Drawing.Graphics]::FromImage($newBitmap)
                    $g2.DrawImage($bitmap, 0, 0, $Width, $targetHeight)
                    $g2.Dispose()
                    $bitmap.Dispose()

                    $memory = New-Object System.IO.MemoryStream
                    $newBitmap.Save($memory, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                    $newBitmap.Dispose()

                    $jpeg = $memory.ToArray()
                    $memory.Dispose()

                    $jpegLen = $jpeg.Length
                    $part = "--frame`r`nContent-Type: image/jpeg`r`nContent-Length: $jpegLen`r`n`r`n"
                    $partBytes = [System.Text.Encoding]::ASCII.GetBytes($part)

                    try {
                        $network.Write($partBytes, 0, $partBytes.Length)
                        $network.Write($jpeg, 0, $jpeg.Length)
                        $crlf = [byte[]](13, 10)
                        $network.Write($crlf, 0, 2)
                        $network.Flush()
                    } catch {
                        break
                    }

                    Start-Sleep -Milliseconds ([int](1000/$FPS))
                }
            } else {
                $htmlBytes = [System.Text.Encoding]::UTF8.GetBytes($html)
                $htmlLen = $htmlBytes.Length
                $response = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $htmlLen`r`nConnection: close`r`n`r`n"
                $responseBytes = [System.Text.Encoding]::ASCII.GetBytes($response)

                $network.Write($responseBytes, 0, $responseBytes.Length)
                $network.Write($htmlBytes, 0, $htmlBytes.Length)
                $network.Flush()
            }
        } catch {
            # Client disconnected
        } finally {
            if ($network) { $network.Close() }
            if ($client) { $client.Close() }
        }
    }
} finally {
    $listener.Stop()
}