Write-Host "================================="
Write-Host "   GAME UPDATE SYSTEM"
Write-Host "================================="

# Поиск Steam
$steamPath = (Get-ItemProperty `
    "HKCU:\Software\Valve\Steam" `
    -ErrorAction SilentlyContinue).SteamPath

if ($steamPath) {
    $steamExe = Join-Path $steamPath "steam.exe"

    if (Test-Path $steamExe) {
        Write-Host "Запускаю Steam..."
        Start-Process $steamExe
    }
}
else {
    Write-Host "Steam не найден"
}

# Поиск Epic Games Launcher
$epicExe = "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"

if (Test-Path $epicExe) {
    Write-Host "Запускаю Epic Games..."
    Start-Process $epicExe
}
else {
    Write-Host "Epic Games Launcher не найден"
}

Write-Host ""
Write-Host "Лаунчеры запущены."
Write-Host "Они самостоятельно проверят обновления."
Write-Host ""
Read-Host "Нажми Enter для выхода"