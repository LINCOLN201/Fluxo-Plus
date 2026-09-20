#!/usr/bin/env bash
# Executa o Fluxo+ em modo desenvolvimento com Supabase configurado.
# Uso: ./scripts/run_dev.sh [dispositivo]
#   ex: ./scripts/run_dev.sh
#       ./scripts/run_dev.sh -d chrome
set -e

SUPABASE_URL="https://pyanwtlyuvppmlivdlxf.supabase.co"
SUPABASE_KEY="sb_publishable_zklfDIovB_o0z26oBh4bFQ_rOxFME-t"

flutter run "$@" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_KEY"
