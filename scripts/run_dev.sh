#!/usr/bin/env bash
# Executa o Fluxo+ em modo desenvolvimento com Supabase configurado.
#
# Nunca coloque a URL ou a chave do Supabase direto neste arquivo: ele é
# versionado. Exporte as variáveis antes de rodar, ou copie para um arquivo
# ".env.local" (fora do git) e faça `source .env.local` antes.
#
# Uso:
#   export SUPABASE_URL="https://SEU-PROJETO.supabase.co"
#   export SUPABASE_PUBLISHABLE_KEY="sb_publishable_..."
#   ./scripts/run_dev.sh
#   ./scripts/run_dev.sh -d chrome
set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]; then
  echo "Defina SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY antes de rodar este" >&2
  echo "script (veja os comentários no topo do arquivo). Sem eles, o app" >&2
  echo "roda normalmente, só sem sincronização com a nuvem." >&2
fi

flutter run "$@" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-}"
