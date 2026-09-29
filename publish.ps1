# 把桌面「桌宠」目录下的 exe 上传到 GitHub Release
# 用法: powershell -ExecutionPolicy Bypass -File publish.ps1 -Repo "用户名/仓库名"

param(
    [Parameter(Mandatory=$true)][string]$Repo,
    [string]$Tag = "v1.0",
    [string]$SfxDir = "",
    [string]$GhExe = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# 定位 gh.exe
if (-not $GhExe) {
    $cand = @(
        "C:\Users\41080\WorkBuddy\2026-09-26-16-07-25\_tools\gh\bin\gh.exe",
        "C:\Program Files\GitHub CLI\gh.exe"
    )
    foreach ($c in $cand) { if (Test-Path $c) { $GhExe = $c; break } }
}
if (-not (Test-Path $GhExe)) { throw "找不到 gh.exe" }

# 定位 exe 来源目录
if (-not $SfxDir) {
    $cand = @("C:\Users\41080\Desktop\桌宠", "$env:USERPROFILE\Desktop\桌宠")
    foreach ($c in $cand) { if (Test-Path $c) { $SfxDir = $c; break } }
}
if (-not (Test-Path $SfxDir)) { throw "找不到桌宠目录" }

Write-Host "gh  : $GhExe"
Write-Host "源  : $SfxDir"
Write-Host "仓库: $Repo"
Write-Host "标签: $Tag"
Write-Host ""

$files = Get-ChildItem $SfxDir -Filter *.exe -File | Sort-Object Name
Write-Host ("共 " + $files.Count + " 个 exe，合计 " + [math]::Round((($files | Measure-Object Length -Sum).Sum/1MB),1) + " MB")
Write-Host ""

if ($DryRun) {
    $files | ForEach-Object { Write-Host ("  [DRY] " + $_.Name) }
    exit 0
}

# 建 release（若已存在则忽略）
& $GhExe release view $Tag --repo $Repo 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "创建 Release $Tag ..."
    & $GhExe release create $Tag --repo $Repo --title "桌宠合集 $Tag" --notes "31 只 Q 版桌宠，单文件 exe，双击即用。详见 README。"
} else {
    Write-Host "Release $Tag 已存在，直接补传。"
}

Write-Host ""
Write-Host "开始上传 ..."
$i = 0
foreach ($f in $files) {
    $i++
    Write-Host ("[$i/" + $files.Count + "] " + $f.Name)
    & $GhExe release upload $Tag $f.FullName --repo $Repo --clobber
    if ($LASTEXITCODE -ne 0) { Write-Warning ("上传失败: " + $f.Name) }
}

Write-Host ""
Write-Host "完成。查看: https://github.com/$Repo/releases/tag/$Tag"
