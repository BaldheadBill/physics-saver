<#
.SYNOPSIS
    One-click installer for Physics-Saver (Windows).

.DESCRIPTION
    Downloads the latest Physics-Saver release binary from GitHub, installs it,
    and optionally configures Claude Desktop and/or Gemini CLI so the tools are
    available in your AI assistant with zero manual setup.

    Designed, built, and copyrighted by VantEdge Intelligence, Atlanta, GA, USA.
    Open-sourced under the MIT License. https://vantedgeintelligence.com/

.PARAMETER InstallDir
    Directory where physics-saver.exe is installed (default: %LOCALAPPDATA%\Physics-Saver).

.PARAMETER ConfigureClaude
    Automatically add the physics-saver MCP server to Claude Desktop
    (%APPDATA%\Claude\claude_desktop_config.json).

.PARAMETER ConfigureGemini
    Automatically add the physics-saver MCP server to Gemini CLI
    (~\.gemini\settings.json).

.PARAMETER SkipDownload
    Do not download; use a physics-saver.exe found next to this script
    (useful for offline installs and testing).

.PARAMETER Uninstall
    Remove the installation and any registered MCP server entries.

.EXAMPLE
    .\install.ps1 -ConfigureClaude -ConfigureGemini

    Downloads, installs, and registers with both Claude Desktop and Gemini CLI.
#>
[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Physics-Saver",
    [switch]$ConfigureClaude,
    [switch]$ConfigureGemini,
    [switch]$SkipDownload,
    [switch]$Uninstall,
    [switch]$DryRun,
    [string]$ClaudeConfigPath = "$env:APPDATA\Claude\claude_desktop_config.json",
    [string]$GeminiConfigPath = "$env:USERPROFILE\.gemini\settings.json"
)

$ErrorActionPreference = 'Stop'
$AppVersion = '3.0.0'
$Repo = 'BaldheadBill/physics-saver'
$ServerName = 'physics-saver'

function Write-Step([string]$msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-WarnMsg([string]$msg) { Write-Host "    WARN: $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Physics-Saver v$AppVersion installer"
Write-Host "  Designed, built, and copyrighted by VantEdge Intelligence, Atlanta, GA, USA"
Write-Host "  Open-sourced under the MIT License. https://vantedgeintelligence.com/"
Write-Host ""

if ($DryRun) { Write-Host "  [DRY RUN - no files will be changed]" -ForegroundColor Magenta; Write-Host "" }

function Merge-McpServerConfig {
    param(
        [string]$ConfigPath,
        [string]$ExePath,
        [string]$StatePath
    )
    $configDir = Split-Path -Parent $ConfigPath
    if (-not (Test-Path $configDir)) {
        if ($DryRun) { Write-Host "    would create: $configDir" }
        else { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    }

    $json = $null
    if (Test-Path $ConfigPath) {
        $raw = Get-Content -LiteralPath $ConfigPath -Raw
        if ($raw -and $raw.Trim()) {
            try { $json = $raw | ConvertFrom-Json } catch {
                Write-WarnMsg "existing config at $ConfigPath is not valid JSON; backing it up and starting fresh"
                Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak" -Force
                $json = $null
            }
        }
    }
    if ($null -eq $json) { $json = [PSCustomObject]@{} }
    if ($null -eq $json.PSObject.Properties['mcpServers']) {
        $json | Add-Member -NotePropertyName 'mcpServers' -NotePropertyValue ([PSCustomObject]@{})
    }

    $serverEntry = [PSCustomObject]@{
        command = $ExePath
        args    = @('mcp')
        env     = [PSCustomObject]@{
            PHYSICS_SAVER_STATE_FILE = $StatePath
        }
    }

    $existing = $json.mcpServers.PSObject.Properties['physics-saver']
    if ($existing) {
        if ($DryRun) { Write-Host "    would update existing '$ServerName' entry in $ConfigPath" }
        else { $json.mcpServers | Add-Member -NotePropertyName $ServerName -NotePropertyValue $serverEntry -Force }
    } else {
        if ($DryRun) { Write-Host "    would add '$ServerName' entry to $ConfigPath" }
        else { $json.mcpServers | Add-Member -NotePropertyName $ServerName -NotePropertyValue $serverEntry }
    }

    if (-not $DryRun) {
        $json | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
        Write-Ok "registered '$ServerName' in $ConfigPath"
        Write-Host "    NOTE: fully quit and restart the AI app for the change to take effect."
    }
}

function Remove-McpServerConfig {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath)) { return }
    if ($DryRun) { Write-Host "    would remove '$ServerName' entry from $ConfigPath"; return }
    try {
        $json = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        if ($null -ne $json.PSObject.Properties['mcpServers']) {
            $json.mcpServers.PSObject.Properties.Remove($ServerName)
            $json | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
            Write-Ok "removed '$ServerName' from $ConfigPath"
        }
    } catch { Write-WarnMsg "could not parse $ConfigPath; leaving it untouched" }
}

# ---------------- Uninstall ----------------
if ($Uninstall) {
    Write-Step "Uninstalling Physics-Saver"
    Remove-McpServerConfig -ConfigPath $ClaudeConfigPath
    Remove-McpServerConfig -ConfigPath $GeminiConfigPath
    if (Test-Path $InstallDir) {
        if ($DryRun) { Write-Host "    would remove: $InstallDir" }
        else {
            Remove-Item -LiteralPath $InstallDir -Recurse -Force
            Write-Ok "removed $InstallDir"
        }
    }
    Write-Host ""
    Write-Host "Physics-Saver has been uninstalled." -ForegroundColor Green
    exit 0
}

# ---------------- Install ----------------
$ExePath = Join-Path $InstallDir 'physics-saver.exe'
$StatePath = Join-Path $InstallDir 'physics-saver-state.json'

Write-Step "1. Locating the Physics-Saver binary"
if (-not $SkipDownload) {
    try {
        Write-Host "    checking GitHub for the latest release..."
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" `
            -Headers @{ 'User-Agent' = 'physics-saver-installer' }
        $asset = $release.assets | Where-Object { $_.name -like 'physics-saver-windows-*.exe' } | Select-Object -First 1
        if (-not $asset) { throw "no Windows binary found in release $($release.tag_name)" }
        $url = $asset.browser_download_url
        $downloadPath = Join-Path $env:TEMP $asset.name
        Write-Host "    downloading $($asset.name)..."
        if ($DryRun) { Write-Host "    (dry run) would download $url" }
        else {
            Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
            if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
            Move-Item -LiteralPath $downloadPath -Destination $ExePath -Force
            Write-Ok "downloaded $($asset.name)"
        }
    } catch {
        Write-WarnMsg "could not reach GitHub ($($_.Exception.Message))"
        Write-Host "    falling back to a local copy next to this script if present..."
        $local = Join-Path $PSScriptRoot 'physics-saver.exe'
        if (Test-Path $local) {
            if ($DryRun) { Write-Host "    (dry run) would install $local" }
            else {
                if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
                Copy-Item -LiteralPath $local -Destination $ExePath -Force
                Write-Ok "installed from local copy"
            }
        } else {
            Write-Host "ERROR: no binary available. Publish a release on GitHub first, or copy" -ForegroundColor Red
            Write-Host "physics-saver.exe next to this script and re-run with -SkipDownload." -ForegroundColor Red
            exit 1
        }
    }
} else {
    $local = Join-Path $PSScriptRoot 'physics-saver.exe'
    if (-not (Test-Path $local)) {
        Write-Host "ERROR: -SkipDownload was used but no physics-saver.exe is next to this script." -ForegroundColor Red
        exit 1
    }
    if ($DryRun) { Write-Host "    (dry run) would install $local" }
    else {
        if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
        Copy-Item -LiteralPath $local -Destination $ExePath -Force
    }
}
if (-not $DryRun -and (Test-Path $ExePath)) {
    Copy-Item -LiteralPath "$PSScriptRoot\LICENSE" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
    Write-Ok "installed to $ExePath"
}

Write-Step "2. Verifying the binary"
if ($DryRun) {
    Write-Host "    (dry run) would run: $ExePath help"
} else {
    $help = & $ExePath help 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $help -match 'Physics-Saver') {
        Write-Ok "binary responds"
    } else {
        Write-WarnMsg "binary did not respond as expected"
    }
}

Write-Step "3. Registering with your AI assistants"
if ($ConfigureClaude) {
    Merge-McpServerConfig -ConfigPath $ClaudeConfigPath -ExePath $ExePath -StatePath $StatePath
} else {
    Write-Host "    Claude Desktop: skipped (re-run with -ConfigureClaude)"
}
if ($ConfigureGemini) {
    Merge-McpServerConfig -ConfigPath $GeminiConfigPath -ExePath $ExePath -StatePath $StatePath
} else {
    Write-Host "    Gemini CLI: skipped (re-run with -ConfigureGemini)"
}

Write-Step "4. Adding the CLI to your PATH"
if ($DryRun) {
    Write-Host "    (dry run) would add $InstallDir to the user PATH"
} else {
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($currentPath -and $currentPath -like "*$InstallDir*") {
        Write-Host "    already on PATH"
    } else {
        [Environment]::SetEnvironmentVariable('Path', "$currentPath;$InstallDir", 'User')
        Write-Ok "added to user PATH (open a new terminal to use 'physics-saver' directly)"
    }
}

Write-Host ""
Write-Host "Done! Next steps:" -ForegroundColor Green
Write-Host "  1. Fully quit and restart Claude Desktop / Gemini CLI (MCP servers load at startup)."
Write-Host "  2. Ask your assistant to use 'ingest_document' with a document path, then"
Write-Host "     'search_documents' to retrieve only the relevant chunks - saving tokens."
Write-Host "  3. Test the CLI any time:  physics-saver help"
Write-Host ""
Write-Host "Need help or found a bug? https://github.com/$Repo/issues"
