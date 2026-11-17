$ErrorActionPreference = "SilentlyContinue"
$Log = Join-Path $PSScriptRoot "launcher-start.log"

function Write-Log($Message) {
    Add-Content -Path $Log -Value "$(Get-Date -Format 'HH:mm:ss') - $Message"
}

function Start-Launcher($Name, $Paths, $Processes) {
    foreach ($ProcessName in $Processes) {
        if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
            Write-Log "$Name уже запущен"
            return
        }
    }

    foreach ($Path in $Paths) {
        if (Test-Path $Path -PathType Leaf) {
            Start-Process -FilePath $Path
            Write-Log "$Name запущен"
            return
        }
    }

    Write-Log "$Name не найден"
}

# ==================================
# STEAM
# ==================================

$SteamRegistry = Get-ItemProperty "HKCU:\Software\Valve\Steam"
$SteamExe = $null

if ($SteamRegistry.SteamPath) {
    $SteamExe = Join-Path $SteamRegistry.SteamPath "steam.exe"
}

if (!$SteamExe -or !(Test-Path $SteamExe)) {
    $SteamExe = "${env:ProgramFiles(x86)}\Steam\steam.exe"
}

if (Test-Path $SteamExe) {
    Start-Launcher "Steam" @($SteamExe) @("steam")
}
else {
    Write-Log "Steam не найден"
}

# ==================================
# EPIC GAMES
# ==================================

$EpicPaths = @(
    "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe",
    "$env:ProgramFiles\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
)

$EpicKeys = @(
    "HKLM:\SOFTWARE\Epic Games\EpicGamesLauncher",
    "HKLM:\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher",
    "HKCU:\SOFTWARE\Epic Games\EpicGamesLauncher"
)

foreach ($Key in $EpicKeys) {
    $Install = (Get-ItemProperty $Key -Name InstallLocation).InstallLocation
    if ($Install) {
        $EpicPaths += Join-Path $Install "Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
    }
}

Start-Launcher "Epic Games" $EpicPaths @("EpicGamesLauncher")

# ==================================
# LESTA GAME CENTER
# ==================================

$LestaPaths = @(
    "C:\ProgramData\Lesta\GameCenter\lgc.exe",
    "${env:ProgramFiles(x86)}\Lesta\GameCenter\lgc.exe",
    "$env:ProgramFiles\Lesta\GameCenter\lgc.exe"
)

$LestaExe = $LestaPaths | Where-Object {
    Test-Path $_ -PathType Leaf
} | Select-Object -First 1

if ($LestaExe) {
    if (Get-Process -Name "lgc" -ErrorAction SilentlyContinue) {
        Write-Log "Lesta уже запущен"
    }
    else {
        Write-Log "Запускаю Lesta"

        $LestaProcess = Start-Process $LestaExe -PassThru

        Start-Sleep -Seconds 10

        $LestaProcess.Refresh()

        if (!$LestaProcess.HasExited) {
            & taskkill.exe /PID $LestaProcess.Id /T /F | Out-Null
            Write-Log "Lesta закрыт через 10 секунд"
        }
    }
}
else {
    Write-Log "Lesta не найден"
}

# ==================================
# VK PLAY GAME CENTER
# ==================================

$VKPaths = @(
    "$env:LOCALAPPDATA\GameCenter\GameCenter.exe",
    "$env:LOCALAPPDATA\VKPlay\GameCenter\GameCenter.exe",
    "${env:ProgramFiles(x86)}\VK Play\GameCenter\GameCenter.exe",
    "$env:ProgramFiles\VK Play\GameCenter\GameCenter.exe"
)

Start-Launcher "VK Play" $VKPaths @("GameCenter")

# ==================================
# ПРОВЕРКА STEAM
# ==================================

function Get-SteamStatus {

    $SteamPath = $SteamRegistry.SteamPath

    if (!$SteamPath) {
        return "UNKNOWN"
    }

    $Libraries = @($SteamPath)
    $Vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"

    if (Test-Path $Vdf) {
        $Content = Get-Content $Vdf -Raw

        $Matches = [regex]::Matches(
            $Content,
            '"path"\s+"([^"]+)"'
        )

        foreach ($Match in $Matches) {
            $Library = $Match.Groups[1].Value -replace '\\\\','\'
            if (Test-Path $Library) {
                $Libraries += $Library
            }
        }
    }

    $Manifests = @()
    foreach ($Library in ($Libraries | Select-Object -Unique)) {
        $AppsPath = Join-Path $Library "steamapps"

        if (Test-Path $AppsPath) {
            $Manifests += Get-ChildItem `
                -Path $AppsPath `
                -Filter "appmanifest_*.acf"
        }
    }

    if ($Manifests.Count -eq 0) {
        return "UNKNOWN"
    }

    foreach ($Manifest in $Manifests) {

        $Data = Get-Content $Manifest.FullName -Raw

        if ($Data -notmatch '"StateFlags"\s+"(\d+)"') {
            return "UNKNOWN"
        }

        $Flags = [int]$Matches[1]

        # 4 = Fully Installed.
        # Любое другое состояние считаем неподтверждённым.
        if ($Flags -ne 4) {
            return "UPDATING"
        }
    }

    return "READY"
}

# ==================================
# МОНИТОРИНГ STEAM
# ==================================

if (Test-Path $SteamExe) {

    Write-Log "Начинаю проверку состояния Steam"

    $CleanChecks = 0
    $MaxChecks = 720

    for ($i = 1; $i -le $MaxChecks; $i++) {

        Start-Sleep -Seconds 30

        if (!(Get-Process -Name "steam" -ErrorAction SilentlyContinue)) {
            Write-Log "Steam уже закрыт"
            break
        }

        $Status = Get-SteamStatus

        Write-Log "Steam: $Status"

        if ($Status -eq "READY") {
            $CleanChecks++
        }
        else {
            $CleanChecks = 0
        }

        # Три последовательные чистые проверки
        if ($CleanChecks -ge 3) {

            Write-Log "Steam: все обнаруженные игры имеют статус Fully Installed"

            Start-Process -FilePath $SteamExe `
                -ArgumentList "-shutdown"

            Write-Log "Отправлена команда закрытия Steam"
            break
        }
    }
}

# ==================================
# ЗАВЕРШЕНИЕ
# ==================================

Write-Log "Скрипт завершил работу"