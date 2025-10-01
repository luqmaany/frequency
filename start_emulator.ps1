# Firebase Emulator Startup Script
# Run this before starting your Flutter app in development mode

Write-Host "🔥 Starting Firebase Emulators..." -ForegroundColor Green
Write-Host ""

# Get local IP address for multi-device testing
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*"} | Select-Object -First 1).IPAddress

Write-Host "📊 Emulator UI: http://localhost:4000" -ForegroundColor Cyan
Write-Host "🗄️  Firestore Emulator: localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 FOR PHYSICAL DEVICES:" -ForegroundColor Yellow
if ($ipAddress) {
    Write-Host "   Set EMULATOR_HOST = '$ipAddress' in lib/main.dart (line 25)" -ForegroundColor White
    Write-Host "   Then access from phones on same WiFi!" -ForegroundColor White
} else {
    Write-Host "   Your IP: Run 'ipconfig' to find it" -ForegroundColor White
    Write-Host "   Set EMULATOR_HOST in lib/main.dart (line 25)" -ForegroundColor White
}
Write-Host ""
Write-Host "💡 TIP: Keep this terminal open while developing!" -ForegroundColor Gray
Write-Host "💰 All reads/writes are FREE in emulator mode!" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the emulators" -ForegroundColor DarkGray
Write-Host ""

firebase emulators:start --only firestore

