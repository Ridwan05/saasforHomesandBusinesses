param(
  [Parameter(Mandatory = $true)]
  [string]$SupabaseUrl,

  [Parameter(Mandatory = $true)]
  [string]$AnonKey
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "public\config.js"
$content = @"
window.SAAS_HOMES_BUSINESSES_CONFIG = {
  SUPABASE_URL: "$SupabaseUrl",
  SUPABASE_ANON_KEY: "$AnonKey",
};
"@

Set-Content -LiteralPath $configPath -Value $content -Encoding UTF8
Write-Host "Updated public/config.js"
