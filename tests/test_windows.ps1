# Dependency-free tests; run with pwsh -NoProfile -File tests/test_windows.ps1.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../install/install.ps1')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles test ' + [guid]::NewGuid())
$originalUserProfile = $env:USERPROFILE
New-Item -ItemType Directory -Path $testRoot | Out-Null
function Assert($condition, $message) { if (-not $condition) { throw $message } }
try {
    $src = Join-Path $testRoot 'source.txt'
    $dst = Join-Path $testRoot 'destination.txt'
    Set-Content -LiteralPath $src 'new'
    Set-Content -LiteralPath $dst 'original'
    Set-Content -LiteralPath "${dst}.bak" 'old backup'
    Copy-Config $src $dst
    Assert ((Get-Content -LiteralPath "${dst}.bak") -eq 'old backup') 'backup overwritten'
    Assert ((Get-Content -LiteralPath "${dst}.bak.1") -eq 'original') 'original lost'
    Copy-Config $src $dst
    Assert (-not (Test-Path -LiteralPath "${dst}.bak.2")) 'identical copy created backup'

    $link = Join-Path $testRoot 'link'
    $missing = Join-Path $testRoot 'missing'
    New-Item -ItemType SymbolicLink -Path $link -Target $missing | Out-Null
    New-Item -ItemType SymbolicLink -Path "${link}.bak" -Target $missing | Out-Null
    Symlink-File $src $link
    Assert ((Get-Item -LiteralPath $link).ResolveLinkTarget($true).FullName -eq $src) 'link not replaced'
    Assert ($null -ne (Get-ExistingItem "${link}.bak.1")) 'broken link not backed up'
    Symlink-File $src $link
    Assert ($null -eq (Get-ExistingItem "${link}.bak.2")) 'link rerun not idempotent'

    # Copy must replace links, never write through to their old targets.
    Copy-Config $src $link
    Assert (-not (Get-Item -LiteralPath $link).LinkType) 'copy destination is still a link'
    Assert ((Get-Content -LiteralPath $src) -eq 'new') 'copy changed link target'

    $directory = Join-Path $testRoot 'old directory'
    $newDirectory = Join-Path $testRoot 'new directory'
    New-Item -ItemType Directory -Path $directory, $newDirectory | Out-Null
    foreach ($kind in @('SymbolicLink') + $(if ($IsWindows) { 'Junction' })) {
        $dirLink = Join-Path $testRoot "directory $kind"
        New-Item -ItemType $kind -Path $dirLink -Target $directory | Out-Null
        Symlink-File $newDirectory $dirLink
        Assert ((Get-ChildItem -LiteralPath $directory).Count -eq 0) 'directory target modified'
        Assert ((Get-Item -LiteralPath "${dirLink}.bak").LinkType -eq $kind) 'directory link not preserved'
    }

    $DryRun = $true
    $dryDst = Join-Path $testRoot 'absent parent/file'
    Copy-Config $src $dryDst
    Symlink-File $src $dryDst
    Assert (-not (Test-Path -LiteralPath (Split-Path $dryDst -Parent))) 'dry run created parent'
    $DryRun = $false
    $failed = $false
    try { Symlink-File $missing $dst } catch { $failed = $true }
    Assert $failed 'missing source accepted'
    Assert ((Get-Content -LiteralPath $dst) -eq 'new') 'missing source damaged destination'

    Register-Failure 'simulated package failure'
    $DryRun = $true
    $failed = $false
    try { Write-PostInstall } catch { $failed = $true }
    Assert $failed 'partial installation reported success'
    $script:InstallFailures.Clear()
    $env:USERPROFILE = Join-Path $testRoot 'fresh profile'
    Main
    Assert (-not (Test-Path -LiteralPath $env:USERPROFILE)) 'full dry run created profile files'
    Write-Host 'Windows installer helper tests passed.'
} finally {
    $env:USERPROFILE = $originalUserProfile
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
