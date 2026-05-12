param(
  [Parameter(Mandatory = $true)]
  [string]$SupabaseUrl,

  [Parameter(Mandatory = $true)]
  [string]$AnonKey
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "public\config.js"
$content = @"
window.INTERCONNECTED_MINIGRID_CONFIG = {
  SUPABASE_URL: "$SupabaseUrl",
  SUPABASE_ANON_KEY: "$AnonKey",
};
"@

Set-Content -LiteralPath $configPath -Value $content -Encoding UTF8
Write-Host "Updated public/config.js"
