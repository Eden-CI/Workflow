#!/bin/sh -e

# ssh into the VPS and setup torrenting, via a script already in the vps home

mkdir -p ~/.ssh
echo "${VPS_SSH_PRIV}" > ~/.ssh/id_ed25519
echo "${VPS_SSH_PUB}" > ~/.ssh/id_ed25519.pub

chmod -R 0700 ~/.ssh

# shellcheck disable=SC2029
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	-p "${VPS_SSH_PORT}" "root@${VPS_SSH_HOST}" backup/artifact.sh "${FORGEJO_REPO}" "${FORGEJO_REF}"

echo "-- done"