$ErrorActionPreference = "SilentlyContinue"

$Log = Join-Path $PSScriptRoot "launcher-start.log"

function Write-Log($Message) {
    Add-Content -Path $Log -Value "$(Get-Date -Format 'HH:mm:ss') - $Message"
}

function Start-Launcher($Name, $Paths, $Processes) {

    # Не запускаем повторно, если лаунчер уже открыт
    foreach ($Process in $Processes) {
        if (Get-Process -Name $Process -ErrorAction SilentlyContinue) {
            Write-Log "$Name уже запущен"
            return
        }
    }

    # Ищем исполняемый файл
    foreach ($Path in $Paths) {
        if (Test-Path $Path -PathType Leaf) {
            try {
                Start-Process -FilePath $Path
                Write-Log "$Name успешно запущен: $Path"
                return
            }
            catch {
                Write-Log "Ошибка запуска $Name : $_"
            }
        }
    }

    Write-Log "$Name не найден. Проверь путь установки."
}

# =========================
# STEAM
# =========================

$SteamPaths = @()

$SteamRegistry = Get-ItemProperty `
    "HKCU:\Software\Valve\Steam" `
    -ErrorAction SilentlyContinue

if ($SteamRegistry.SteamPath) {
    $SteamPaths += Join-Path $SteamRegistry.SteamPath "steam.exe"
}

$SteamPaths += "${env:ProgramFiles(x86)}\Steam\steam.exe"
$SteamPaths += "$env:ProgramFiles\Steam\steam.exe"

Start-Launcher "Steam" $SteamPaths @("steam")

# =========================
# EPIC GAMES LAUNCHER
# =========================

$EpicPaths = @()

$EpicKeys = @(
    "HKLM:\SOFTWARE\Epic Games\EpicGamesLauncher",
    "HKLM:\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher",
    "HKCU:\SOFTWARE\Epic Games\EpicGamesLauncher",
    "HKCU:\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher"
)

foreach ($Key in $EpicKeys) {
    $Install = (Get-ItemProperty -Path $Key `
        -Name InstallLocation -ErrorAction SilentlyContinue).InstallLocation

    if ($Install) {
        $EpicPaths += Join-Path $Install "Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
        $EpicPaths += Join-Path $Install "Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
    }
}

$EpicPaths += "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
$EpicPaths += "$env:ProgramFiles\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"

Start-Launcher "Epic Games" $EpicPaths @("EpicGamesLauncher")

# =========================
# LESTA GAME CENTER
# =========================

$LestaPaths = @(
    "C:\ProgramData\Lesta\GameCenter\lgc.exe",
    "${env:ProgramFiles(x86)}\Lesta\GameCenter\lgc.exe",
    "$env:ProgramFiles\Lesta\GameCenter\lgc.exe"
)

Start-Launcher "Lesta Game Center" $LestaPaths @("lgc")

# =========================
# VK PLAY GAME CENTER
# =========================

$VKPaths = @(
    "$env:LOCALAPPDATA\GameCenter\GameCenter.exe",
    "$env:LOCALAPPDATA\VKPlay\GameCenter\GameCenter.exe",
    "${env:ProgramFiles(x86)}\VK Play\GameCenter\GameCenter.exe",
    "$env:ProgramFiles\VK Play\GameCenter\GameCenter.exe"
)

Start-Launcher "VK Play GameCenter" $VKPaths @("GameCenter")

Write-Log "Запуск всех лаунчеров завершён"