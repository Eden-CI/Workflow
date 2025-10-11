#!/usr/bin/python3

import os
import requests
import json

FORGEJO_HOST = os.getenv("FORGEJO_HOST")
FORGEJO_REPO = os.getenv("FORGEJO_REPO")
PR_API_URL = f"https://{FORGEJO_HOST}/api/v1/repos/{FORGEJO_REPO}/pulls"
FORGEJO_PR_NUMBER = os.getenv("FORGEJO_PR_NUMBER")
FORGEJO_TOKEN = os.getenv("FORGEJO_TOKEN")
DEFAULT_MSG = os.getenv("DEFAULT_MSG")
FIELD = os.getenv("FIELD")

def get_pr_json():
    headers = {"Authorization": f"token {FORGEJO_TOKEN}"} if FORGEJO_TOKEN else {}
    response = requests.get(f"{PR_API_URL}/{FORGEJO_PR_NUMBER}", headers=headers)
    return response.json()

def get_pr_field():
    try:
        pr_json = get_pr_json()
        return pr_json.get(FIELD, DEFAULT_MSG)
    except:
        return DEFAULT_MSG

field = get_pr_field().replace("`", "\\`")
print(field if field != "" else DEFAULT_MSG)
