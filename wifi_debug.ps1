# List of your phone IPs
$deviceIps = @(
    "192.168.0.84",   # Phone 1
    "192.168.0.213",  # Phone 2
    "192.168.0.177"   # SM P610 (R52R50EX6BD)
)
$port = "5555"

Write-Host "🔌 Checking for connected devices (USB or Wi-Fi)..."
adb devices

Write-Host "📡 Restarting ADB in TCP/IP mode for any USB-connected devices..."
adb tcpip $port

foreach ($ip in $deviceIps) {
    Write-Host "📶 Trying to connect to ${ip}:$port..."
    try {
        $output = adb connect "${ip}:$port" 2>&1
        if ($output -match "connected" -or $output -match "already connected") {
            Write-Host "✅ ${ip} connected."
        }
        else {
            Write-Host "⚠ ${ip} not connected: $output"
        }
    }
    catch {
        Write-Host "❌ Error connecting to ${ip}"
    }
}

Write-Host "`n📋 Final list of devices:"
flutter devices
