#!/bin/sh -e

SUMMARY="## Job Summary
- Triggered by: $1
- Commit: [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF)
"

if [ "$FORGEJO_MIRROR" = true ]; then
SUMMARY="$SUMMARY
## Using mirror:
- Mirror URL: [\`$FORGEJO_HOST/$FORGEJO_REPO\`]($FORGEJO_CLONE_URL)
"
fi

master() {
	cat << EOF
## Master

- Full changelog: [\`$FORGEJO_BEFORE...$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/compare/$FORGEJO_BEFORE...$FORGEJO_REF)
EOF
}

pull_request() {
cat << EOF
## Pull Request"
This is a build for pull request #[${FORGEJO_PR_NUMBER}]($FORGEJO_PR_URL). This commit's merge base with master is [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)

## Changelog
$FORGEJO_PR_TITLE

EOF

	.ci/common/field.py field="body" default_msg="No changelog provided" pull_request_number="$FORGEJO_PR_NUMBER"
}

push() {
	cat << EOF
## Continuous Build

This was triggered by a push to the Workflow repository.
EOF
}

test() {
	cat << EOF
## Test Build

This is a testing build, either for a pull request or a different branch.
EOF
}

tag() {
	cat << EOF
## Release Build

This is a release build for the [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/src/tag/$FORGEJO_REF) tag.
EOF
}

case "$1" in
master | pull_request | push | test | tag)
		SUMMARY="$SUMMARY
$($1)
"
	;;
*)
	SUMMARY="## Unknown Build Type
Build type '$1' is not recognized.
"
	;;
esac

echo "$SUMMARY" >> "$GITHUB_STEP_SUMMARY"
