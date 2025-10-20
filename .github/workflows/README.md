# Eden Workflow

## Create a Personal Access Token (PAT)

Since these workflows need to push to another repository (see `release.json`), the default `GITHUB_TOKEN` does **not** have cross-repository permissions. You need to create a **Fine-grained Personal Access Token**:

1. Go to: [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **Generate new token** → **Fine-grained, repo-scoped**.
3. Choose a **Token name** and **Resource owner**.
4. Set an expiration date (recommended).
5. Under **Repository access**, select **Only select repositories**.
6. Select `{OWNER}/Master`, `{OWNER}/PR` and other repos set on `release.json`.
7. Set permissions:
    - **Contents**: `Read and write`
8. Generate the token and copy it.
9. Save the token as a secret named `CUSTOM_GITHUB_TOKEN` in the `Workflow` repository:
    - Go to:
      `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

---

If you have any questions or want to contribute, feel free to open an issue or pull request.
