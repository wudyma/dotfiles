#Requires -Version 7.2
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
    [switch]$DryRun,
    [switch]$LinksOnly
)

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path $PSScriptRoot -Parent
$script:InstallFailures = [System.Collections.Generic.List[string]]::new()

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

function Register-Failure($message) {
    $script:InstallFailures.Add($message)
    Write-Warn $message
}

function Get-ExistingItem($path) {
    # Get-Item sees dangling symlinks as well as files, directories and junctions.
    Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
}

function Backup-Existing($dst) {
    if ($null -eq (Get-ExistingItem $dst)) { return }
    $backup = "${dst}.bak"
    $suffix = 0
    while ($null -ne (Get-ExistingItem $backup)) {
        $suffix++
        $backup = "${dst}.bak.$suffix"
    }
    Write-Warn "$dst exists, backing up to $backup"
    if (-not $DryRun) {
        # Rename within the same parent; never traverse directory links/junctions.
        Rename-Item -LiteralPath $dst -NewName (Split-Path $backup -Leaf)
    }
}

function Symlink-File($src, $dst) {
    if (-not (Test-Path -LiteralPath $src)) { throw "Missing symlink source: $src" }
    $item = Get-ExistingItem $dst
    if ($null -ne $item -and $item.LinkType -eq "SymbolicLink") {
        $target = $item.ResolveLinkTarget($true)
        if ($null -ne $target -and $target.FullName -eq (Get-Item -LiteralPath $src).FullName) {
            Write-Info "already linked: $dst"
            return
        }
    }
    Backup-Existing $dst
    if ($DryRun) { Write-Info "[dry-run] link $src → $dst"; return }
    $parent = Split-Path $dst -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Ok
}

function Copy-Config($src, $dst) {
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { throw "Missing copy source: $src" }
    $item = Get-ExistingItem $dst
    if ($null -ne $item -and -not $item.PSIsContainer -and -not $item.LinkType -and
        (Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $dst).Hash) {
        Write-Info "already copied: $dst"
        return
    }
    Backup-Existing $dst
    if ($DryRun) { Write-Info "[dry-run] copy $src → $dst"; return }
    New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst
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
        @{ id = "GitHub.cli"; name = "gh" }
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
                Register-Failure "failed to install $($pkg.name) — continuing"
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
            if ($LASTEXITCODE -ne 0) { Register-Failure "failed to install bun" } else { Write-Ok }
        }
    } else {
        Write-Info "bun already installed"
    }

    # uv — fast Python package manager
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Write-Step "installing uv"
        if (-not $DryRun) {
            powershell -c "irm astral.sh/uv/install.ps1 | iex"
            if ($LASTEXITCODE -ne 0) { Register-Failure "failed to install uv" } else { Write-Ok }
        }
    } else {
        Write-Info "uv already installed"
    }

    # claude — Claude Code CLI (tmux popup binding)
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Step "installing Claude Code CLI"
        if (-not $DryRun) {
            if (Get-Command bun -ErrorAction SilentlyContinue) {
                bun add -g @anthropic-ai/claude-code
            } else {
                npm install -g @anthropic-ai/claude-code
            }
            if ($LASTEXITCODE -ne 0) { Register-Failure "failed to install Claude Code" } else { Write-Ok }
        }
    } else {
        Write-Info "claude already installed"
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
                Register-Failure "failed to install $($pkg.name) — continuing"
            } else {
                Write-Ok
            }
        }
    }
}

# ─── Nerd Font ───────────────────────────────────────────────────────────────
function Install-NerdFont {
    if ($DryRun) { Write-Info "[dry-run] would install Maple Mono NF CN font"; return }
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

    $userHome = $env:USERPROFILE

    # Git config — copy (git on Windows sometimes has trouble with symlinks)
    $gitSrc = Join-Path $DotfilesDir ".gitconfig"
    $gitDst = Join-Path $userHome ".gitconfig"
    Copy-Config $gitSrc $gitDst

    # SSH config
    $sshSrc = Join-Path $DotfilesDir "ssh\config"
    $sshDst = Join-Path $userHome ".ssh\config"
    Symlink-File $sshSrc $sshDst

    if (-not $DryRun) {
        New-Item -ItemType Directory -Path (Join-Path $userHome ".ssh/config.d") -Force | Out-Null
    }

    # Claude config files only; credentials and local state remain separate.
    Symlink-File (Join-Path $DotfilesDir "claude/settings.json") (Join-Path $userHome ".claude/settings.json")
    Symlink-File (Join-Path $DotfilesDir "claude/CLAUDE.md") (Join-Path $userHome ".claude/CLAUDE.md")

    # PowerShell profile
    $pwshProfileDst = Join-Path $userHome "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $pwshProfileSrc = Join-Path $DotfilesDir "config\powershell\Microsoft.PowerShell_profile.ps1"
    Symlink-File $pwshProfileSrc $pwshProfileDst

    # Neovim (AppData\Local\nvim on Windows)
    $nvimSrc  = Join-Path $DotfilesDir "config\nvim"
    $nvimDst  = Join-Path $userHome "AppData\Local\nvim"
    Symlink-File $nvimSrc $nvimDst

    # Zed
    $zedSrc = Join-Path $DotfilesDir "config\zed"
    $zedDst = Join-Path $userHome ".config\zed"
    Symlink-File $zedSrc $zedDst

    # Starship
    $starshipSrc = Join-Path $DotfilesDir "config\starship.toml"
    $starshipDst = Join-Path $userHome ".config\starship.toml"
    Symlink-File $starshipSrc $starshipDst

    # Windows Terminal (copy to LocalState, not symlink — Terminal expects it there)
    $wtSrc = Join-Path $DotfilesDir "config\windows_terminal\settings.json"
    $wtDst = Join-Path $userHome "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path (Split-Path $wtDst -Parent)) {
        Write-Step "copying Windows Terminal settings"
        Copy-Config $wtSrc $wtDst
    } else {
        Write-Info "Windows Terminal package dir not found; skipping settings.json"
    }

    # Yazi file manager
    $yaziSrc = Join-Path $DotfilesDir "config\yazi"
    $yaziDst = Join-Path $userHome "AppData\Roaming\yazi\config"
    Symlink-File $yaziSrc $yaziDst
}

# ─── post-install ────────────────────────────────────────────────────────────
function Write-PostInstall {
    Write-Header "Post-install"

    if (-not $DryRun -and -not $LinksOnly) {
        New-Item -ItemType Directory -Path (Join-Path $env:USERPROFILE "repos") -Force | Out-Null
    }

    if ($script:InstallFailures.Count -gt 0) {
        Write-Warn "Setup completed with $($script:InstallFailures.Count) failure(s):"
        $script:InstallFailures | ForEach-Object { Write-Warn $_ }
        throw "Dotfiles installation incomplete"
    }
    if ($DryRun) { Write-Info "Preview complete; no changes made." }
    else { Write-Info "Requested setup completed. Restart your terminal." }
}

# ─── main ────────────────────────────────────────────────────────────────────
function Main {
    Write-Host ""
    Write-Host "  Dotfiles installer for Windows" -ForegroundColor Magenta
    Write-Host "  ───────────────────────────────" -ForegroundColor Magenta

    if (-not $LinksOnly) {
        if (-not $DryRun) { Assert-Winget }
        Install-Packages
        Install-ManualTools
        Install-RecommendedTools
        Install-NerdFont
    }
    Link-Dotfiles
    Write-PostInstall
}

if ($MyInvocation.InvocationName -ne '.') { Main }
