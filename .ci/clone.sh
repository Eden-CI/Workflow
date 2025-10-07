#!/bin/sh -e

TRIES=0

while ! git clone $FORGEJO_CLONE_URL eden; do
  echo "Clone failed!"
  TRIES=$(($TRIES + 1))
  if [ "$TRIES" = 10 ]; then
    echo "Failed to clone after ten tries. Exiting."
    exit 1
  fi

  sleep 5
  echo "Trying clone again..."
  rm -rf ./eden || true
done

cd eden
git remote add https://git.eden-emu.dev/octocar/eden.git
git fetch --all
git checkout "$FORGEJO_REF"

echo "$FORGEJO_BRANCH" > GIT-REFSPEC
git rev-parse --short=10 HEAD > GIT-COMMIT
git describe --tags HEAD --abbrev=0 > GIT-TAG || echo 'v0.0.3' > GIT-TAG

if [ "$1" = "tag" ]; then
  cp GIT-TAG GIT-RELEASE
fi