param(
    [ValidateSet("run", "build-apk", "build-appbundle")]
    [string]$Action = "run",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$frontDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path (Split-Path -Parent $frontDir) "backEnd\.env"

if (-not (Test-Path -LiteralPath $envPath)) {
    throw "Arquivo de configuracao nao encontrado: $envPath"
}

function Read-DotEnv([string]$Path) {
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#") -or -not $trimmed.Contains("=")) {
            continue
        }
        $name, $value = $trimmed.Split("=", 2)
        $value = $value.Trim()
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $values[$name.Trim()] = $value
    }
    return $values
}

function Get-SecretFingerprint([string]$Value) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hash = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").Substring(0, 12)
    } finally {
        $sha.Dispose()
    }
}

$environment = Read-DotEnv $envPath
$appApiKey = $environment["FOLHIO_APP_API_KEY"]
if ([string]::IsNullOrWhiteSpace($appApiKey)) {
    throw "FOLHIO_APP_API_KEY nao foi configurada em $envPath"
}

$defines = @{
    FOLHIO_APP_API_KEY = $appApiKey
    FOLHIO_API_BASE_URL = if ($environment["FOLHIO_API_BASE_URL"]) {
        $environment["FOLHIO_API_BASE_URL"]
    } else {
        "https://flyover-army-handed.ngrok-free.dev"
    }
}

if ($environment["FOLHIO_API_PROXY_BYPASS_HEADER"]) {
    $defines["FOLHIO_API_PROXY_BYPASS_HEADER"] = $environment["FOLHIO_API_PROXY_BYPASS_HEADER"]
}

if ($environment["FOLHIO_API_PROXY_BYPASS_VALUE"]) {
    $defines["FOLHIO_API_PROXY_BYPASS_VALUE"] = $environment["FOLHIO_API_PROXY_BYPASS_VALUE"]
}

Write-Host "Folhio: usando API $($defines["FOLHIO_API_BASE_URL"])"
Write-Host "Folhio: chave do app carregada de backEnd\.env (sha256 inicio: $(Get-SecretFingerprint $appApiKey))"

$googleClientId = if ($environment["GOOGLE_WEB_CLIENT_ID"]) {
    $environment["GOOGLE_WEB_CLIENT_ID"]
} else {
    $environment["FOLHIO_GOOGLE_CLIENT_ID"]
}

if (-not [string]::IsNullOrWhiteSpace($googleClientId)) {
    $defines["GOOGLE_WEB_CLIENT_ID"] = $googleClientId
    $defines["FOLHIO_GOOGLE_CLIENT_ID"] = $googleClientId
}

$definesPath = Join-Path ([System.IO.Path]::GetTempPath()) "folhio-defines-$([guid]::NewGuid()).json"
$defines | ConvertTo-Json | Set-Content -LiteralPath $definesPath -Encoding utf8

$commandArgs = switch ($Action) {
    "run" { @("run") }
    "build-apk" { @("build", "apk") }
    "build-appbundle" { @("build", "appbundle") }
}
$hasBuildMode = $FlutterArgs -contains "--debug" -or
    $FlutterArgs -contains "--profile" -or
    $FlutterArgs -contains "--release"
if ($Action -ne "run" -and -not $hasBuildMode) {
    $commandArgs += "--release"
}
$commandArgs += "--dart-define-from-file=$definesPath"
if ($FlutterArgs) {
    $commandArgs += $FlutterArgs
}

try {
    Push-Location $frontDir
    & flutter @commandArgs
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
    Remove-Item -LiteralPath $definesPath -Force -ErrorAction SilentlyContinue
}

exit $exitCode
