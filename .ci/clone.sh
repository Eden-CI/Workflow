while ! git clone $FORGEJO_CLONE_URL eden; do
  echo "Clone failed!"
  sleep 5
  echo "Trying clone again..."
  rm -rf ./eden || true
done

cd eden
git reset --hard $FORGEJO_REF

if [ "$1" = "true" ]; then
  git submodule update --init --recursive
fi
