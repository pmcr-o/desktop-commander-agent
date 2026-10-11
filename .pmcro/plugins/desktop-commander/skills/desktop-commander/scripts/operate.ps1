[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('list','read','search','process','write')][string]$Operation,
    [Parameter(Mandatory=$true)][string]$Workspace,
    [string]$Path='.',
    [string]$Pattern='',
    [string]$Content='',
    [int]$MaxBytes=4096,
    [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($MaxBytes -lt 1 -or $MaxBytes -gt 65536) { throw 'MaxBytes must be 1..65536' }
$root=(Resolve-Path -LiteralPath $Workspace).Path
if (-not $root.EndsWith([IO.Path]::DirectorySeparatorChar)) { $root += [IO.Path]::DirectorySeparatorChar }
if ([IO.Path]::IsPathRooted($Path)) { throw 'Path must be workspace-relative' }
$full=[IO.Path]::GetFullPath((Join-Path $root $Path))
if (-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { throw 'Path escapes workspace' }
switch ($Operation) {
  'list' {
    if (-not (Test-Path -LiteralPath $full -PathType Container)) { throw 'List target is not a directory' }
    Get-ChildItem -LiteralPath $full -Force | Select-Object -ExpandProperty Name
  }
  'read' {
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw 'Read target is not a file' }
    $bytes=[IO.File]::ReadAllBytes($full); if($bytes.Length -gt $MaxBytes){$bytes=$bytes[0..($MaxBytes-1)]}; [Text.Encoding]::UTF8.GetString($bytes)
  }
  'search' {
    if (-not $Pattern) { throw 'Search requires Pattern' }
    if (-not (Test-Path -LiteralPath $full)) { throw 'Search target does not exist' }
    Get-ChildItem -LiteralPath $full -File -Recurse -Force | Select-String -SimpleMatch -Pattern $Pattern | ForEach-Object { '{0}:{1}:{2}' -f $_.Path,$_.LineNumber,$_.Line.Trim() }
  }
  'process' {
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw 'Process target must be an existing workspace-relative file' }
    $ext=[IO.Path]::GetExtension($full).ToLowerInvariant(); if($ext -notin @('.ps1','.py','.cmd','.bat')){throw 'Process supports .ps1, .py, .cmd, or .bat only'}
    if(-not $Apply){Write-Output "DRY-RUN process $full"; exit 0}
    if($ext -eq '.ps1'){& pwsh -NoProfile -File $full}
    elseif($ext -eq '.py'){& python $full}
    else{& cmd /c $full}
    exit $LASTEXITCODE
  }
  'write' {
    if(-not $Apply){Write-Output "DRY-RUN write $full bytes=$([Text.Encoding]::UTF8.GetByteCount($Content))"; exit 0}
    $parent=Split-Path -Parent $full; if(-not(Test-Path -LiteralPath $parent -PathType Container)){throw 'Write parent must already exist'}
    [IO.File]::WriteAllText($full,$Content,[Text.UTF8Encoding]::new($false)); Write-Output "WROTE $full"
  }
}
