param(
  [string]$Flutter = "flutter"
)

$ErrorActionPreference = "Stop"

& $Flutter create `
  --project-name fluxo_plus `
  --org br.com.fluxoplus `
  --platforms android,ios,windows,macos,linux `
  .

& $Flutter pub get
& $Flutter analyze
& $Flutter test
