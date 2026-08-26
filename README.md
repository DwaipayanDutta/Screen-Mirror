# 🖥️ Screen Mirror

<p align="center">
  <strong>PC Screen → Android / Mobile Wi-Fi Mirror</strong><br>
  <em>Mirror your Windows desktop to a mobile browser over your local Wi-Fi network.</em>
</p>

<p align="center">

![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Wi-Fi](https://img.shields.io/badge/Local%20Wi--Fi-00B8D9?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-22C55E?style=for-the-badge)

</p>

---

## ✨ Overview

**Screen Mirror** is a lightweight Windows desktop-to-mobile screen streaming utility built with native PowerShell and .NET.

It captures the Windows desktop, converts frames to JPEG, and serves them as an **MJPEG HTTP stream** over the local network. Your Android phone, tablet, iPhone, or other browser-capable device can connect using a normal browser.

### No external software required

- ❌ No FFmpeg
- ❌ No Python
- ❌ No Node.js
- ❌ No Android app
- ❌ No cloud service
- ✅ Windows PowerShell
- ✅ Windows .NET assemblies
- ✅ Local Wi-Fi
- ✅ Mobile browser

---

## 🚀 Features

| Feature | Description |
|---|---|
| 🖥️ Desktop Capture | Captures the Windows primary display |
| 📱 Mobile Browser | Works from a normal mobile browser |
| 📡 Local Wi-Fi | PC and phone communicate directly over LAN |
| 🔍 Auto IP Detection | Detects the PC's local IPv4 address |
| 🔥 Firewall Support | Adds the Windows Firewall rule when elevated |
| 🎛️ Configurable | Port, FPS and output width are configurable |
| 📦 Portable | Keep the scripts together and run them from one folder |
| 🔒 LAN Focused | Intended for trusted local networks |

---

# 🛠️ Quick Start

## 1. Download or clone

```bash
git clone https://github.com/<YOUR-USERNAME>/Screen-Mirror.git
cd Screen-Mirror
```

Or download the repository ZIP and extract it.

## 2. Start the mirror

Keep these files together:

```text
Screen-Mirror/
├── run.bat
├── screen_mirror.ps1
├── LICENSE
└── README.md
```

Right-click `run.bat` and select **Run as administrator**.

The launcher will:

1. Start PowerShell.
2. Detect the local IPv4 address.
3. Configure the Windows Firewall rule for port `8080`.
4. Start the screen capture server.
5. Display the URL for your phone.

Example:

```text
====================================================================
     WIFI SCREEN MIRROR
     PC  >  ANDROID / MOBILE  >  LOCAL WIFI
====================================================================

  CONNECTION

      PHONE URL
      http://192.168.1.15:8080

      RESOLUTION     1280 px wide
      FRAME RATE     8 FPS
      NETWORK        Local WiFi only
      PORT           8080

      STATUS         READY
====================================================================
```

---

# 📱 Connect from Android

Make sure the PC and phone are connected to the **same Wi-Fi network**.

Open Chrome or another browser on your phone and enter the address shown by the launcher:

```text
http://<YOUR-PC-IP>:8080
```

Example:

```text
http://192.168.1.15:8080
```

Do not use `localhost` or `127.0.0.1` on the phone.

---

# ⚙️ Configuration

Edit the values near the top of `screen_mirror.ps1`:

```powershell
$Port  = 8080
$FPS   = 8
$Width = 1280
```

| Parameter | Default | Description |
|---|---:|---|
| `$Port` | `8080` | Local TCP/HTTP port |
| `$FPS` | `8` | Target frames per second |
| `$Width` | `1280` | Output width; height scales automatically |

### Lower bandwidth

```powershell
$FPS   = 6
$Width = 960
```

### Balanced

```powershell
$FPS   = 8
$Width = 1280
```

### Smoother

```powershell
$FPS   = 12
$Width = 1280
```

Higher FPS and resolution increase CPU and network usage.

> This implementation uses JPEG/MJPEG frames rather than hardware H.264/H.265 encoding. It prioritizes zero external dependencies and simple browser access.

---

# 🔍 How It Works

```text
┌──────────────────────┐       HTTP / MJPEG       ┌──────────────────────┐
│      WINDOWS PC      │ ───────────────────────> │   ANDROID / MOBILE   │
│                      │          Wi-Fi           │                      │
│  Desktop Capture     │                          │    Web Browser       │
│        ↓             │                          │         ↓            │
│  Resize Frame        │                          │   Live Screen View   │
│        ↓             │                          │                      │
│  JPEG Encode         │                          │                      │
│        ↓             │                          │                      │
│  TCP Listener :8080  │                          │                      │
└──────────────────────┘                          └──────────────────────┘
```

### Processing pipeline

```text
Windows Desktop
      ↓
Graphics.CopyFromScreen()
      ↓
Resize to $Width
      ↓
JPEG encoding
      ↓
multipart/x-mixed-replace
      ↓
TCP / HTTP
      ↓
Mobile browser
```

### Components

**TCP Listener**

Uses:

```text
System.Net.Sockets.TcpListener
```

**Screen Capture**

Uses:

```powershell
System.Drawing.Graphics.CopyFromScreen()
```

**Scaling**

Frames are resized to the configured `$Width` while maintaining the aspect ratio.

**MJPEG**

Frames are served using:

```text
multipart/x-mixed-replace; boundary=frame
```

---

# 🔐 Windows Firewall

The launcher attempts to create:

```text
PC Screen Mirror 8080
```

for TCP port `8080` on the Windows Private network profile.

If required, run Command Prompt as Administrator:

```cmd
netsh advfirewall firewall add rule name="PC Screen Mirror 8080" dir=in action=allow protocol=TCP localport=8080 profile=private
```

Remove it later with:

```cmd
netsh advfirewall firewall delete rule name="PC Screen Mirror 8080"
```

---

# 🖥️ PowerShell Direct Mode

You can run the server directly:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\screen_mirror.ps1
```

Or temporarily bypass the execution policy:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\screen_mirror.ps1
```

Running as Administrator is recommended when the script needs to configure the Firewall.

---

# ❓ Troubleshooting

## Phone cannot connect

Check the PC's IP:

```cmd
ipconfig
```

Find the Wi-Fi adapter IPv4 address, for example:

```text
192.168.1.15
```

Then open:

```text
http://192.168.1.15:8080
```

## Guest Wi-Fi / AP isolation

Some routers prevent wireless clients from communicating.

Check for:

```text
AP Isolation
Client Isolation
Wireless Isolation
Guest Isolation
```

Use the normal/private Wi-Fi network instead of an isolated guest network.

## Firewall

Run:

```cmd
netsh advfirewall firewall add rule name="PC Screen Mirror 8080" dir=in action=allow protocol=TCP localport=8080 profile=private
```

## Port 8080 is already in use

Check:

```cmd
netstat -ano | findstr :8080
```

Change:

```powershell
$Port = 8080
```

to another port such as:

```powershell
$Port = 8090
```

Then use:

```text
http://<YOUR-PC-IP>:8090
```

## Stream is slow

Try:

```powershell
$FPS   = 6
$Width = 960
```

Lower FPS and resolution reduce CPU and network usage.

---

# 🔒 Security Notes

This project is designed for **local-network use**.

Anyone able to reach the exposed port may potentially access the screen stream.

Therefore:

- Use it only on trusted networks.
- Prefer a Windows **Private** network profile.
- Do not expose port `8080` to the public Internet.
- Do not configure router port forwarding.
- Remove the Firewall rule when finished.

---

# 📂 Repository Structure

```text
📦 Screen-Mirror
│
├── 📜 run.bat
│   └── Launcher / elevation wrapper
│
├── 📜 screen_mirror.ps1
│   └── PowerShell streaming server
│
├── 📜 LICENSE
│   └── MIT License
│
└── 📜 README.md
    └── Documentation
```

---

# 🧪 Architecture

```text
┌─────────────────────────────┐
│        Windows Desktop      │
│                             │
│  GDI+ Screen Capture        │
│           │                 │
│           ▼                 │
│     JPEG Encoding           │
│           │                 │
│           ▼                 │
│   TCP Listener : 8080       │
└─────────────┬───────────────┘
              │
              │ Local Wi-Fi
              │ HTTP / MJPEG
              ▼
┌─────────────────────────────┐
│       Android / Mobile      │
│                             │
│       Chrome / Browser      │
│             │               │
│             ▼               │
│       Live PC Screen        │
└─────────────────────────────┘
```

---

# 🚧 Roadmap

- [ ] WebRTC streaming
- [ ] H.264 hardware encoding
- [ ] 30/60 FPS mode
- [ ] Audio streaming
- [ ] Multi-monitor selection
- [ ] Quality controls
- [ ] Adaptive bitrate
- [ ] QR-code connection
- [ ] Mobile control panel
- [ ] Authentication
- [ ] HTTPS support
- [ ] Windows system-tray launcher

---

# 📜 License

Distributed under the **MIT License**.

See [LICENSE](LICENSE) for details.

---

## ❤️ Credits

Built with native Windows PowerShell and .NET.

**Screen Mirror — PC → Mobile → Local Wi-Fi**

> Simple. Local. Dependency-free.
