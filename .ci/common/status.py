#!/usr/bin/env python3

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Description: Sends CI/CD build status to Forgejo commit and optionally posts a PR comment.

import os
import requests

# --- Required Forgejo environment variables ---
FORGEJO_HOST = os.getenv("FORGEJO_HOST")
FORGEJO_REPO = os.getenv("FORGEJO_REPO")
FORGEJO_REF = os.getenv("FORGEJO_REF")
FORGEJO_PR_NUMBER = os.getenv("FORGEJO_PR_NUMBER")
FORGEJO_TOKEN = os.getenv("FORGEJO_TOKEN")
FORGEJO_TOKEN_INVALID_STATUS = os.getenv("FORGEJO_TOKEN_INVALID_STATUS", "")

# --- GitHub Actions environment for workflow URL ---
GITHUB_SERVER_URL = os.getenv("GITHUB_SERVER_URL", "https://github.com")
GITHUB_REPOSITORY = os.getenv("GITHUB_REPOSITORY")
GITHUB_RUN_ID = os.getenv("GITHUB_RUN_ID")
GITHUB_RUN_ATTEMPT = os.getenv("GITHUB_RUN_ATTEMPT", "1")

def build_workflow_url():
    """Construct workflow run URL from GitHub Actions env."""
    if GITHUB_REPOSITORY and GITHUB_RUN_ID:
        return f"{GITHUB_SERVER_URL}/{GITHUB_REPOSITORY}/actions/runs/{GITHUB_RUN_ID}/attempts/{GITHUB_RUN_ATTEMPT}"
    return None

WORKFLOW_URL = build_workflow_url()

# --- Validate token ---
def is_token_valid():
    """Check if Forgejo token is valid before sending requests."""
    if not FORGEJO_TOKEN:
        print("[WARN] FORGEJO_TOKEN not set, skipping requests.")
        return False
    if FORGEJO_TOKEN == FORGEJO_TOKEN_INVALID_STATUS:
        print("[WARN] FORGEJO_TOKEN previously marked invalid, skipping requests.")
        return False
    return True

# --- Send commit status ---
def send_commit_status(state):
    """Send build status to the last commit of the PR."""
    if not is_token_valid():
        return
    if not (FORGEJO_HOST and FORGEJO_REPO and FORGEJO_REF):
        print("[WARN] Missing repository or commit info, cannot send commit status.")
        return
    if not WORKFLOW_URL:
        print("[WARN] Missing GITHUB_RUN_ID, cannot build workflow link, skipping status.")
        return

    api_url = f"https://{FORGEJO_HOST}/api/v1/repos/{FORGEJO_REPO}/statuses/{FORGEJO_REF}"

    status_mapping = {
        "pending": "pending",
        "success": "success",
        "failure": "failure",
        "error": "error"
    }

    description_mapping = {
        "pending": "Build started",
        "success": "Build succeeded",
        "failure": "Build failed",
        "error": "Build cancelled"
    }

    if state not in status_mapping:
        print(f"[WARN] Unknown state '{state}', skipping commit status.")
        return

    data = {
        "state": status_mapping[state],
        "target_url": WORKFLOW_URL,
        "description": f"[CI] {description_mapping[state]}",
        "context": "GitHub Actions"
    }

    headers = {"Authorization": f"token {FORGEJO_TOKEN}", "Content-Type": "application/json"}

    try:
        r = requests.post(api_url, headers=headers, json=data, timeout=10)
        if r.status_code not in (200, 201):
            print(f"[WARN] Failed to send commit status: HTTP {r.status_code} -> {r.text}")
            if r.status_code == 401:
                print("[INFO] Token unauthorized, skipping further requests.")
        else:
            print(f"[INFO] Commit status sent successfully: {state}")
    except Exception as e:
        print(f"[ERROR] Exception while sending commit status: {e}")

# --- Optional PR comment ---
def send_pr_comment(state):
    """Send or update a build status comment on the PR referencing the last commit and attempt."""
    if not is_token_valid():
        return
    if not (FORGEJO_HOST and FORGEJO_REPO and FORGEJO_PR_NUMBER and FORGEJO_REF):
        print("[INFO] PR number or commit not set, skipping PR comment.")
        return

    if not GITHUB_RUN_ID:
        print("[WARN] Missing GITHUB_RUN_ID, cannot build workflow link, skipping PR comment.")
        return

    api_url = f"https://{FORGEJO_HOST}/api/v1/repos/{FORGEJO_REPO}/issues/{FORGEJO_PR_NUMBER}/comments"
    headers = {"Authorization": f"token {FORGEJO_TOKEN}", "Content-Type": "application/json"}

    # --- Single message template with variable final word ---
    status_word = {
        "pending": "started",
        "success": "succeeded",
        "failure": "failed",
        "error": "error"
    }

    if state not in status_word:
        print(f"[WARN] Unknown state '{state}', skipping PR comment.")
        return

    message_body = (
        f"[CI] Build Status - [Details]({WORKFLOW_URL})\n"
        f" - GitHub Run: {GITHUB_RUN_ID}\n"
        f" - Attempt number: {GITHUB_RUN_ATTEMPT}\n"
        f" - Status: {status_word[state]}\n"
    )
    data = {"body": message_body}

    # --- Check existing comments ---
    try:
        r = requests.get(api_url, headers=headers, timeout=10)
        if r.status_code != 200:
            print(f"[WARN] Failed to fetch PR comments: HTTP {r.status_code} -> {r.text}")
            return
        comments = r.json()
    except Exception as e:
        print(f"[ERROR] Exception while fetching PR comments: {e}")
        return

    # --- Find bot comment for the same attempt ---
    bot_comment_id = None
    for comment in comments:
        body = comment.get("body", "")
        if body.startswith("[CI]") and f"Attempt number: {GITHUB_RUN_ATTEMPT}" in body:
            bot_comment_id = comment["id"]
            break

    try:
        if bot_comment_id:
            # Update existing comment
            update_url = f"{api_url}/{bot_comment_id}"
            r = requests.patch(update_url, headers=headers, json=data, timeout=10)
            if r.status_code not in (200, 201):
                print(f"[WARN] Failed to update PR comment: HTTP {r.status_code} -> {r.text}")
            else:
                print(f"[INFO] PR comment updated successfully: {state} (attempt {GITHUB_RUN_ATTEMPT})")
        else:
            # Create new comment for this attempt
            r = requests.post(api_url, headers=headers, json=data, timeout=10)
            if r.status_code not in (200, 201):
                print(f"[WARN] Failed to post PR comment: HTTP {r.status_code} -> {r.text}")
            else:
                print(f"[INFO] PR comment posted successfully: {state} (attempt {GITHUB_RUN_ATTEMPT})")
    except Exception as e:
        print(f"[ERROR] Exception while sending PR comment: {e}")

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: status.py <state> [--pr-comment]")
        print("States: pending, success, failure, error")
        print("Optional flag: --pr-comment  # Post PR comment in addition to commit status")
        exit(1)

    state = sys.argv[1].lower()
    post_pr_comment = "--pr-comment" in sys.argv

    send_commit_status(state)

    # Send PR comment only if requested
    if post_pr_comment:
        send_pr_comment(state)

