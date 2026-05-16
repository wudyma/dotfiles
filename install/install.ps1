#Requires -Version 7.0
<#
.SYNOPSIS
    Install dotfiles and dependencies on Windows.
.DESCRIPTION
    Installs all required tools (neovim, lazygit, eza, git, etc.) via winget,
    then symlinks dotfiles into the appropriate locations.
.NOTES
    Run this script from an elevated PowerShell session, then re-run as normal
    user if you see permission errors on symlinks.
#>

param(
    [switch]$NoFonts,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path $PSScriptRoot -Parent

# ─── helpers ─────────────────────────────────────────────────────────────────
function Write-Header($msg) {
    Write-Host "`n" -NoNewline
    Write-Host "==> " -ForegroundColor Cyan -NoNewline
    Write-Host $msg -ForegroundColor Cyan
}
function Write-Step($msg) { Write-Host "  → $msg" -ForegroundColor Yellow }
function Write-Ok { Write-Host "    ✓" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    ⚠ $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "    $msg" -ForegroundColor Gray }

function Symlink-File($src, $dst) {
    if ($DryRun) { Write-Info "[dry-run] link $src → $dst"; return }

    if (Test-Path $dst) {
        $item = Get-Item $dst -ErrorAction SilentlyContinue
        if ($item.LinkType -eq "SymbolicLink" -and (Get-Item $item.Target).FullName -eq (Resolve-Path $src).Path) {
            Write-Info "already linked: $dst"
            return
        }
        Write-Warn "$dst exists, backing up to ${dst}.bak"
        Move-Item $dst "${dst}.bak" -Force
    }
    # Ensure parent exists
    $parent = Split-Path $dst -Parent
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Write-Ok
}

# ─── ensure winget ───────────────────────────────────────────────────────────
function Assert-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "winget available"
        return
    }
    # winget ships with App Installer on Win 10 1809+ / Win 11
    # Try installing via Microsoft Store
    Write-Warn "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
    Write-Info "Alternatively: https://github.com/microsoft/winget-cli/releases"
    exit 1
}

# ─── install packages ────────────────────────────────────────────────────────
function Install-Packages {
    Write-Header "Installing packages via winget"

    $packages = @(
        # Development
        @{ id = "Git.Git"; name = "git" }
        @{ id = "Neovim.Neovim"; name = "neovim" }
        @{ id = "OpenJS.NodeJS"; name = "node" }
        @{ id = "Microsoft.VisualStudioCode"; name = "vscode" }
        # CLI tools
        @{ id = "JesseDuffield.lazygit"; name = "lazygit" }
        @{ id = "eza-community.eza"; name = "eza" }
        @{ id = "sharkdp.bat"; name = "bat" }
        @{ id = "Starship.Starship"; name = "starship" }
        @{ id = "ajeetdsouza.zoxide"; name = "zoxide" }
        @{ id = "junegunn.fzf"; name = "fzf" }
        @{ id = "sharkdp.fd"; name = "fd" }
        @{ id = "BurntSushi.ripgrep.MSVC"; name = "ripgrep" }
        @{ id = "x-motemen.ghq"; name = "ghq" }
        # Terminal / shell
        @{ id = "Microsoft.PowerShell"; name = "pwsh" }
        @{ id = "Microsoft.WindowsTerminal"; name = "windows-terminal" }
    )

    foreach ($pkg in $packages) {
        Write-Step "winget install $($pkg.name)"
        if ($DryRun) {
            Write-Info "[dry-run] winget install --id $($pkg.id)"
            continue
        }
        $installed = winget list --id $($pkg.id) --exact 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "$($pkg.name) already installed"
        } else {
            winget install --id $($pkg.id) --exact --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) {
                Write-Warn "failed to install $($pkg.name) — continuing"
            } else {
                Write-Ok
            }
        }
    }
}

# ─── manual installs (tools not in winget) ───────────────────────────────────
function Install-ManualTools {
    Write-Header "Installing tools not available via winget"

    # peco — download binary
    if (-not (Get-Command peco -ErrorAction SilentlyContinue)) {
        Write-Step "installing peco"
        if (-not $DryRun) {
            $pecoVer = (Invoke-RestMethod https://api.github.com/repos/peco/peco/releases/latest).tag_name
            $zip = "$env:TEMP\peco.zip"
            Invoke-WebRequest "https://github.com/peco/peco/releases/download/${pecoVer}/peco_windows_amd64.zip" -OutFile $zip
            Expand-Archive $zip -DestinationPath "$env:TEMP\peco" -Force
            $dest = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory $dest -Force | Out-Null }
            Copy-Item "$env:TEMP\peco\peco_windows_amd64\peco.exe" $dest -Force
            Remove-Item $zip; Remove-Item "$env:TEMP\peco" -Recurse -Force
            Write-Ok
        }
    } else {
        Write-Info "peco already installed"
    }
}

# ─── Nerd Font ───────────────────────────────────────────────────────────────
function Install-NerdFont {
    if ($NoFonts) { Write-Info "skipping fonts (--NoFonts)"; return }
    Write-Header "Installing JetBrains Mono Nerd Font"

    $fontName = "JetBrainsMono Nerd Font"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (Get-ItemProperty -Path $regPath -Name "$fontName (TrueType)" -ErrorAction SilentlyContinue) {
        Write-Info "JetBrains Mono Nerd Font already installed"
        return
    }

    Write-Step "downloading JetBrainsMono.zip"
    if (-not $DryRun) {
        $zip = "$env:TEMP\JetBrainsMono.zip"
        Invoke-WebRequest "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -OutFile $zip
        $fontDir = "$env:TEMP\JetBrainsMono"
        Expand-Archive $zip -DestinationPath $fontDir -Force

        # Install per-user
        $userFontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        if (-not (Test-Path $userFontDir)) { New-Item -ItemType Directory $userFontDir -Force | Out-Null }
        Get-ChildItem $fontDir -Filter "*.ttf" | ForEach-Object {
            Copy-Item $_.FullName $userFontDir -Force
        }
        # Register fonts
        Get-ChildItem $userFontDir -Filter "JetBrainsMono*.ttf" | ForEach-Object {
            $fontFile = $_.Name
            New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
                -Name $fontFile -Value $_.FullName -PropertyType String -Force | Out-Null
        }
        Remove-Item $zip; Remove-Item $fontDir -Recurse -Force
        Write-Ok
    }
}

# ─── symlink dotfiles ────────────────────────────────────────────────────────
function Link-Dotfiles {
    Write-Header "Linking dotfiles"

    $home = $env:USERPROFILE

    # git config — copy (git on Windows sometimes has trouble with symlinks)
    $gitSrc = Join-Path $DotfilesDir ".gitconfig"
    $gitDst = Join-Path $home ".gitconfig"
    if ($DryRun) {
        Write-Info "[dry-run] copy $gitSrc → $gitDst"
    } elseif (-not (Test-Path $gitDst) -or (Get-Item $gitDst).LinkType -ne "SymbolicLink") {
        Write-Step "copying .gitconfig"
        Copy-Item $gitSrc $gitDst -Force
        Write-Ok
    }

    # PowerShell profile
    $pwshProfileDst = Join-Path $home "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $pwshProfileSrc = Join-Path $DotfilesDir ".config\powershell\Microsoft.PowerShell_profile.ps1"
    Symlink-File $pwshProfileSrc $pwshProfileDst

    # PowerShell config dirs
    $nvimSrc  = Join-Path $DotfilesDir ".config\nvim"
    $nvimDst  = Join-Path $home "AppData\Local\nvim"
    Symlink-File $nvimSrc $nvimDst

    $lazygitSrc = Join-Path $DotfilesDir ".config\lazygit"
    $lazygitDst = Join-Path $home "AppData\Local\lazygit"
    Symlink-File $lazygitSrc $lazygitDst

    $zedSrc = Join-Path $DotfilesDir ".config\zed"
    $zedDst = Join-Path $home ".config\zed"
    Symlink-File $zedSrc $zedDst

    # starship config goes in ~/.config
    Write-Info "Note: starship config is handled by starship.toml if present"
}

# ─── post-install ────────────────────────────────────────────────────────────
function Write-PostInstall {
    Write-Header "Post-install"

    if (-not $DryRun) {
        mkdir ~/repos -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐"
    Write-Host "  │  ✓  Dotfiles installed!                                 │"
    Write-Host "  │                                                         │"
    Write-Host "  │  Next steps:                                            │"
    Write-Host "  │  • Restart your terminal                                │"
    Write-Host "  │  • In nvim: :Lazy sync to install plugins               │"
    Write-Host "  │  • Set Windows Terminal font to:                        │"
    Write-Host "  │      JetBrainsMono Nerd Font                            │"
    Write-Host "  └─────────────────────────────────────────────────────────┘"
    Write-Host ""
}

# ─── main ────────────────────────────────────────────────────────────────────
function Main {
    Write-Host ""
    Write-Host "  Dotfiles installer for Windows" -ForegroundColor Magenta
    Write-Host "  ───────────────────────────────" -ForegroundColor Magenta

    Assert-Winget
    Install-Packages
    Install-ManualTools
    Install-NerdFont
    Link-Dotfiles
    Write-PostInstall
}

Main
