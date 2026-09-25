#!/usr/bin/env python3
"""Avisa quem já instalou o Fluxo+ que uma nova versão saiu.

Manda uma notificação push para o tópico "atualizacoes" do Firebase Cloud
Messaging — o mesmo que o app assina sozinho (sem conta, sem ID de
aparelho). Chamado pelo workflow .github/workflows/release.yml depois que
a Release do GitHub é publicada.

Variáveis de ambiente esperadas:
  FIREBASE_PROJECT_ID              — id do projeto no console do Firebase
  FIREBASE_SERVICE_ACCOUNT_JSON    — caminho do arquivo da conta de serviço
  VERSION                          — número da versão (ex.: "0.6.1")
"""

import os
import sys

import google.auth.transport.requests
import requests
from google.oauth2 import service_account

TOPIC = "atualizacoes"


def main() -> int:
    project_id = os.environ["FIREBASE_PROJECT_ID"]
    account_path = os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"]
    version = os.environ["VERSION"]

    credentials = service_account.Credentials.from_service_account_file(
        account_path,
        scopes=["https://www.googleapis.com/auth/firebase.messaging"],
    )
    credentials.refresh(google.auth.transport.requests.Request())

    message = {
        "message": {
            "topic": TOPIC,
            "notification": {
                "title": "Chegou atualização do Fluxo+ 🚀",
                "body": (
                    f"A versão {version} já está disponível. "
                    "Toque para atualizar."
                ),
            },
            "android": {"notification": {"channel_id": TOPIC}},
        }
    }
    response = requests.post(
        f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send",
        headers={"Authorization": f"Bearer {credentials.token}"},
        json=message,
        timeout=15,
    )
    print(response.status_code, response.text)
    response.raise_for_status()
    return 0


if __name__ == "__main__":
    sys.exit(main())
