#!/usr/bin/env python3
"""Confere se o Secret FIREBASE_SERVICE_ACCOUNT_BASE64 está utilizável.

Antes disso, um valor presente mas errado (Base64 corrompido, JSON sem os
campos certos, `project_id` que não bate com FIREBASE_PROJECT_ID) só
falharia dentro do notify_update.py, sem dizer qual Secret conferir.
Chamado pelo workflow .github/workflows/release.yml antes de notificar.

Variáveis de ambiente esperadas:
  FIREBASE_PROJECT_ID              — id do projeto no console do Firebase
  FIREBASE_SERVICE_ACCOUNT_JSON    — caminho do arquivo já decodificado
"""

import json
import os
import sys

REQUIRED_FIELDS = ("project_id", "client_email", "private_key")


def main() -> int:
    account_path = os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"]
    project_id = os.environ["FIREBASE_PROJECT_ID"]

    try:
        with open(account_path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception as error:
        print(
            "FIREBASE_SERVICE_ACCOUNT_BASE64 não decodifica para um JSON "
            f"válido: {error}",
            file=sys.stderr,
        )
        return 1

    missing = [field for field in REQUIRED_FIELDS if not data.get(field)]
    if missing:
        print(
            f"FIREBASE_SERVICE_ACCOUNT_BASE64 sem os campos {missing} — "
            "confira o JSON da conta de serviço.",
            file=sys.stderr,
        )
        return 1

    if data["project_id"] != project_id:
        print(
            "FIREBASE_PROJECT_ID não bate com o project_id da conta de "
            "serviço.",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
