# Actions Secrets

## Distribution

- `FORGEJO_TOKEN` - Token to a Forgejo account with access to release repositories. Must have `repository:write`, `issue:write`, `misc:write` and `user:read`
- `DISCORD_WEBHOOK` - URL to a discord webhook for announcing Nightlies

## Backblaze

See <https://www.backblaze.com/docs/cloud-storage-use-cli-to-create-an-application>. These are used for Backblaze distribution

- `B2_TOKEN` - The application key for your Backblaze bucket
- `B2_KEY` - The key ID for your Backblaze bucket

## Android

You must first create a keystore. With a JDK installed and in PATH:

`keytool -genkey -v -keystore android.keystore -alias <ALIAS> -keyalg RSA -keysize 2048 -validity 10000`

Follow the prompts, and take note of your alias and password.

- `ANDROID_KEYSTORE_B64` - base64-encoded Android keystore file
  - `openssl base64 -in android.keystore`
- `ANDROID_KEY_ALIAS` - the key alias you just created
- `ANDROID_KEYSTORE_PASS` - password to the keystore you just created

## Cloudflare

Solely used to purge "latest" caches, may be used for more later.

- `CF_ZONE_ID` - The zone ID for your domain
- `CF_TOKEN` - An account access token with `Zone.Cache Purge.Purge` permissions on your domain

## SSH

Currently unused, document later plz
