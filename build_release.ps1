# ==============================================================================
# Supermarket App Release Build & Auto-Increment Script
# ==============================================================================
param(
    [switch]$Install,
    [string]$DeviceId = "10BEA511UQ0015J"
)

$ErrorActionPreference = "Stop"
$rootDir = $PSScriptRoot
Set-Location $rootDir

$propsFile = Join-Path $rootDir "version.properties"
if (-not (Test-Path $propsFile)) {
    @"
major=0
minor=0
versionCode=1
"@ | Out-File -FilePath $propsFile -Encoding utf8
}

# Read current version
$props = ConvertFrom-StringData (Get-Content $propsFile -Raw)
$major = if ($props.major) { $props.major.Trim() } else { "0" }
$minor = if ($props.minor) { $props.minor.Trim() } else { "0" }
$code = if ($props.versionCode) { [int]$props.versionCode.Trim() } else { 1 }

$versionName = "$major.$minor"
$targetApkName = "supermarket-version-$versionName.apk"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "BUILDING SUPERMARKET RELEASE APK" -ForegroundColor Green
Write-Host "Target Version: $versionName" -ForegroundColor Yellow
Write-Host "Target APK:     $targetApkName" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# Synchronize android/app/version.properties
$appPropsFile = Join-Path $rootDir "android\app\version.properties"
Copy-Item -Path $propsFile -Destination $appPropsFile -Force

# Run flutter release build
Write-Host "Running flutter build apk --release ..." -ForegroundColor Gray
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Verify output APK
$outputDir = Join-Path $rootDir "build\app\outputs\flutter-apk"
$releaseApkPath = Join-Path $outputDir "app-release.apk"
$namedApkPath = Join-Path $outputDir $targetApkName

# Copy to root release_apks directory for convenience
$releaseFolder = Join-Path $rootDir "release_apks"
if (-not (Test-Path $releaseFolder)) {
    New-Item -ItemType Directory -Path $releaseFolder -Force | Out-Null
}
$finalReleasePath = Join-Path $releaseFolder $targetApkName

if (Test-Path $releaseApkPath) {
    Copy-Item -Path $releaseApkPath -Destination $namedApkPath -Force
    Copy-Item -Path $releaseApkPath -Destination $finalReleasePath -Force
}

if (-not (Test-Path $namedApkPath)) {
    Write-Host "Could not find output APK at $namedApkPath" -ForegroundColor Red
    exit 1
}

$apkSizeMB = [math]::Round(((Get-Item $finalReleasePath).Length / 1MB), 2)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "RELEASE BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "APK Name: $targetApkName" -ForegroundColor Cyan
Write-Host "Size:     $apkSizeMB MB" -ForegroundColor Cyan
Write-Host "File 1:   $namedApkPath" -ForegroundColor White
Write-Host "File 2:   $finalReleasePath" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Green

# Auto-increment version for the next build
$nextMinor = [int]$minor + 1
$nextCode = $code + 1

@"
major=$major
minor=$nextMinor
versionCode=$nextCode
"@ | Out-File -FilePath $propsFile -Encoding utf8

Copy-Item -Path $propsFile -Destination $appPropsFile -Force

Write-Host "Next build version auto-incremented to: supermarket-version-$major.$nextMinor (Code: $nextCode)`n" -ForegroundColor Magenta

# Optional: Install to connected Android device
if ($Install) {
    Write-Host "Installing $targetApkName to device $DeviceId..." -ForegroundColor Yellow
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $adbPath) {
        & $adbPath -s $DeviceId install -r $finalReleasePath
        & $adbPath -s $DeviceId shell monkey -p com.freshness.supermarket.supermarket_customer -c android.intent.category.LAUNCHER 1
        Write-Host "Installed and Launched on device!" -ForegroundColor Green
    } else {
        Write-Host "adb not found at $adbPath; skipping device install." -ForegroundColor DarkYellow
    }
}
