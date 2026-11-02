# Import-Module posh-git
# Import-Module -Name Terminal-Icons

# PSReadLine
# Set-PSReadLineOption -EditMode Emacs
# Set-PSReadLineOption -BellStyle None
# Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
# Set-PSReadLineOption -PredictionSource History

# Fzf
# Import-Module PSFzf
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Utilities
Function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

Function ln ($link, $target) {
  New-Item -ItemType SymbolicLink -Path $link -Target $target
}

Function peco_src() {
  if (-not (Get-Command ghq -ErrorAction SilentlyContinue) -or
      -not (Get-Command peco -ErrorAction SilentlyContinue)) { return }
  $directory = ghq list -p | peco
  if ($directory -and (Test-Path -LiteralPath $directory -PathType Container)) {
    Set-Location -LiteralPath $directory
  }
}

if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
  Set-PSReadLineKeyHandler -Chord Ctrl+] -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("peco_src")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
  Function eza_ls { eza --color auto --icons @args }
  Function eza_ll { eza -l --color auto --icons @args }
  Function eza_lla { eza -l -a -g --color auto --icons @args }
  Set-Alias ls eza_ls
  Set-Alias ll eza_ll
  Set-Alias lla eza_lla
}

# Alias
Set-Alias g git
Set-Alias grep findstr
foreach ($tool in 'tig', 'less') {
  if ($env:ProgramFiles) {
    $toolPath = Join-Path $env:ProgramFiles "Git\usr\bin\$tool.exe"
    if (Test-Path -LiteralPath $toolPath) { Set-Alias $tool $toolPath }
  }
}
if (Get-Command nvim -ErrorAction SilentlyContinue) { Set-Alias vim nvim }
Remove-Variable tool, toolPath -ErrorAction SilentlyContinue

# Point starship at the Windows-compatible config
$env:STARSHIP_CONFIG = "$env:USERPROFILE\.config\starship.toml"
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
