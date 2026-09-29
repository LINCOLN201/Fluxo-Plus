#!/usr/bin/env python3
"""Confere se o Secret GOOGLE_SERVICES_JSON_BASE64 está utilizável.

Sem isso, o build publicado nunca tem o Firebase configurado de verdade —
mesmo com FIREBASE_PROJECT_ID/FIREBASE_SERVICE_ACCOUNT_BASE64 certos e o job
"Avisar quem já instalou" enviando a notificação, o aparelho nunca a recebe
porque o app compilado não sabe se inscrever em nenhum tópico do Firebase
Cloud Messaging. Chamado pelo workflow .github/workflows/release.yml antes
de compilar o APK.

Variáveis de ambiente esperadas:
  GOOGLE_SERVICES_JSON_PATH — caminho do arquivo já decodificado
"""

import json
import os
import sys

PACKAGE_NAME = "br.com.fluxoplus.app"


def main() -> int:
    path = os.environ["GOOGLE_SERVICES_JSON_PATH"]

    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception as error:
        print(
            f"GOOGLE_SERVICES_JSON_BASE64 não decodifica para um JSON válido: {error}",
            file=sys.stderr,
        )
        return 1

    if not data.get("project_info", {}).get("project_id"):
        print(
            "GOOGLE_SERVICES_JSON_BASE64 sem project_info.project_id — "
            "confira se é o arquivo certo, baixado do Firebase.",
            file=sys.stderr,
        )
        return 1

    packages = {
        client.get("client_info", {}).get("android_client_info", {}).get(
            "package_name"
        )
        for client in data.get("client", [])
    }
    if PACKAGE_NAME not in packages:
        print(
            f"GOOGLE_SERVICES_JSON_BASE64 não tem um app Android cadastrado "
            f"com o pacote {PACKAGE_NAME} — confira o app criado no console "
            "do Firebase (seção 5.1 de docs/RELEASES.md).",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
