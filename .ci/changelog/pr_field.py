#!/usr/bin/python3

import os
import requests

FORGEJO_HOST = os.getenv("FORGEJO_HOST")
FORGEJO_REPO = os.getenv("FORGEJO_REPO")
FORGEJO_PR_NUMBER = os.getenv("FORGEJO_PR_NUMBER")
FORGEJO_BRANCH = os.getenv("FORGEJO_BRANCH")
FORGEJO_TOKEN = os.getenv("FORGEJO_TOKEN")
DEFAULT_MSG = os.getenv("DEFAULT_MSG") or ""
FIELD = os.getenv("FIELD") or "title"

PR_API_URL = f"https://{FORGEJO_HOST}/api/v1/repos/{FORGEJO_REPO}/pulls/{FORGEJO_PR_NUMBER}"
COMMITS_API_URL = f"https://{FORGEJO_HOST}/api/v1/repos/{FORGEJO_REPO}/commits?sha={FORGEJO_BRANCH}&limit=1"

def get_pr_json():
    headers = {"Authorization": f"token {FORGEJO_TOKEN}"} if FORGEJO_TOKEN else {}
    response = requests.get(PR_API_URL, headers=headers)
    response.raise_for_status()
    return response.json()

def get_latest_commit():
    headers = {"Authorization": f"token {FORGEJO_TOKEN}"} if FORGEJO_TOKEN else {}
    response = requests.get(COMMITS_API_URL, headers=headers)
    response.raise_for_status()
    data = response.json()
    if not isinstance(data, list) or len(data) == 0:
        raise RuntimeError(f"No commits found for branch '{FORGEJO_BRANCH}' in {FORGEJO_REPO}")
    return data[0]["sha"]

def get_field():
    try:
        if FORGEJO_PR_NUMBER:
            pr_json = get_pr_json()
            return pr_json.get(FIELD, DEFAULT_MSG)
        elif FIELD.lower() == "sha":
            return get_latest_commit()
        else:
            return DEFAULT_MSG
    except requests.exceptions.RequestException:
        return DEFAULT_MSG

field_value = get_field().replace("`", "\\`")
print(field_value if field_value else DEFAULT_MSG)
