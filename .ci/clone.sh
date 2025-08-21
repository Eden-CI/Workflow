#!/bin/sh -x

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
git fetch --all
git reset --hard $FORGEJO_REF

# if [ "$1" = "true" ]; then
git submodule update --init --recursive
# fi
