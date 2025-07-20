#!/usr/bin/python3

import os
import requests
import json

PR_API_URL = "https://git.eden-emu.dev/api/v1/repos/eden-emu/eden/pulls"
FORGEJO_NUMBER = os.getenv("FORGEJO_NUMBER")
FORGEJO_TOKEN = os.getenv("FORGEJO_TOKEN")
DEFAULT_MSG = "No changelog provided."

def get_pr_json():
    headers = {"Authorization": f"token {FORGEJO_TOKEN}"}
    response = requests.get(f"{PR_API_URL}/{FORGEJO_NUMBER}", headers=headers)
    return response.json()

def get_pr_description():
    try:
        pr_json = get_pr_json()
        return pr_json.get("body", DEFAULT_MSG)
    except:
        return DEFAULT_MSG

description = get_pr_description()
print(description if description != "" else DEFAULT_MSG)