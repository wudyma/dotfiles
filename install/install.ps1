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
        @{ id = "Zed.Zed"; name = "zed" }
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
        @{ id = "jqlang.jq"; name = "jq" }
        # Terminal / shell
        @{ id = "Microsoft.PowerShell"; name = "pwsh" }
        @{ id = "Microsoft.WindowsTerminal"; name = "windows-terminal" }
        # File manager
        @{ id = "sxyazi.yazi"; name = "yazi" }
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

    # bun — fast JS runtime
    if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
        Write-Step "installing bun"
        if (-not $DryRun) {
            powershell -c "irm bun.sh/install.ps1 | iex"
            Write-Ok
        }
    } else {
        Write-Info "bun already installed"
    }

    # uv — fast Python package manager
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Write-Step "installing uv"
        if (-not $DryRun) {
            powershell -c "irm astral.sh/uv/install.ps1 | iex"
            Write-Ok
        }
    } else {
        Write-Info "uv already installed"
    }
}

# ─── recommended tools ───────────────────────────────────────────────────────
function Install-RecommendedTools {
    Write-Header "Installing recommended CLI tools"

    $recs = @(
        @{ id = "dandavison.delta"; name = "delta (git diff viewer)" }
        @{ id = "bootandy.dust"; name = "dust (disk usage)" }
        @{ id = "Clement.bottom"; name = "bottom (system monitor)" }
        @{ id = "ducaale.xh"; name = "xh (HTTP client)" }
    )

    foreach ($pkg in $recs) {
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

# ─── Nerd Font ───────────────────────────────────────────────────────────────
function Install-NerdFont {
    if ($NoFonts) { Write-Info "skipping fonts (--NoFonts)"; return }
    Write-Header "Installing Maple Mono NF CN (Nerd Font with Chinese)"

    $userFontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (-not (Test-Path $userFontDir)) { New-Item -ItemType Directory $userFontDir -Force | Out-Null }

    if (Get-ChildItem $userFontDir -Filter "MapleMono*" -ErrorAction SilentlyContinue) {
        Write-Info "Maple Mono NF CN already installed"
        return
    }

    Write-Step "downloading MapleMono-NF-CN.zip"
    if (-not $DryRun) {
        $zip = "$env:TEMP\MapleMono-NF-CN.zip"
        try {
            Invoke-WebRequest "https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN.zip" -OutFile $zip
        } catch {
            Write-Warn "failed to download Maple Mono; falling back to JetBrains Mono"
            Invoke-WebRequest "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -OutFile $zip
        }
        $fontDir = "$env:TEMP\MapleMonoFont"
        Expand-Archive $zip -DestinationPath $fontDir -Force

        Get-ChildItem $fontDir -Filter "*.ttf" -Recurse | ForEach-Object {
            Copy-Item $_.FullName $userFontDir -Force
        }
        # Register fonts
        Get-ChildItem $userFontDir -Filter "MapleMono*.ttf" | ForEach-Object {
            $fontFile = $_.Name
            New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
                -Name $fontFile -Value $_.FullName -PropertyType String -Force | Out-Null
        }
        Remove-Item $zip -ErrorAction SilentlyContinue
        Remove-Item $fontDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Ok
    }
}

# ─── symlink dotfiles ────────────────────────────────────────────────────────
function Link-Dotfiles {
    Write-Header "Linking dotfiles"

    $home = $env:USERPROFILE

    # Git config — copy (git on Windows sometimes has trouble with symlinks)
    $gitSrc = Join-Path $DotfilesDir ".gitconfig"
    $gitDst = Join-Path $home ".gitconfig"
    if ($DryRun) {
        Write-Info "[dry-run] copy $gitSrc → $gitDst"
    } elseif (-not (Test-Path $gitDst) -or (Get-Item $gitDst).LinkType -ne "SymbolicLink") {
        Write-Step "copying .gitconfig"
        Copy-Item $gitSrc $gitDst -Force
        Write-Ok
    }

    # SSH config
    $sshSrc = Join-Path $DotfilesDir "ssh\config"
    $sshDst = Join-Path $home ".ssh\config"
    Symlink-File $sshSrc $sshDst

    # PowerShell profile
    $pwshProfileDst = Join-Path $home "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $pwshProfileSrc = Join-Path $DotfilesDir "config\powershell\Microsoft.PowerShell_profile.ps1"
    Symlink-File $pwshProfileSrc $pwshProfileDst

    # Neovim (AppData\Local\nvim on Windows)
    $nvimSrc  = Join-Path $DotfilesDir "config\nvim"
    $nvimDst  = Join-Path $home "AppData\Local\nvim"
    Symlink-File $nvimSrc $nvimDst

    # Zed
    $zedSrc = Join-Path $DotfilesDir "config\zed"
    $zedDst = Join-Path $home ".config\zed"
    Symlink-File $zedSrc $zedDst

    # Starship
    $starshipSrc = Join-Path $DotfilesDir "config\starship_windows.toml"
    $starshipDst = Join-Path $home ".config\starship.toml"
    Symlink-File $starshipSrc $starshipDst

    # Windows Terminal (copy to LocalState, not symlink — Terminal expects it there)
    $wtSrc = Join-Path $DotfilesDir "config\windows_terminal\settings.json"
    $wtDst = Join-Path $home "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path (Split-Path $wtDst -Parent)) {
        Write-Step "copying Windows Terminal settings"
        if (-not $DryRun) { Copy-Item $wtSrc $wtDst -Force; Write-Ok }
    } else {
        Write-Info "Windows Terminal package dir not found; skipping settings.json"
    }

    # Yazi file manager
    $yaziSrc = Join-Path $DotfilesDir "config\yazi"
    $yaziDst = Join-Path $home "AppData\Roaming\yazi\config"
    Symlink-File $yaziSrc $yaziDst
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
    Write-Host "  │      Maple Mono NF CN                                    │"
    Write-Host "  │  • Try new tools: yazi (file manager), delta (git diff) │"
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
    Install-RecommendedTools
    Install-NerdFont
    Link-Dotfiles
    Write-PostInstall
}

Main
