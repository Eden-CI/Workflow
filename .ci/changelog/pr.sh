#!/bin/sh -ex

TAG=${FORGEJO_PR_NUMBER}-${FORGEJO_REF}
REF=${FORGEJO_PR_NUMBER}-${FORGEJO_REF}

brief() {
	echo "This is pull request number [$FORGEJO_PR_NUMBER]($FORGEJO_PR_URL), ref [\`$FORGEJO_REF\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_REF) of Eden."
	echo
	echo "This PR's merge base is [\`$FORGEJO_PR_MERGE_BASE\`](https://$FORGEJO_HOST/$FORGEJO_REPO/commit/$FORGEJO_PR_MERGE_BASE)."
	echo "The corresponding master build can be found [here](https://github.com/Eden-CI/Master/releases?q=$FORGEJO_PR_MERGE_BASE&expanded=true)"
}

changelog() {
	echo "## Changelog"
	echo
	FIELD=body DEFAULT_MSG="No changelog provided" FORGEJO_PR_NUMBER=$FORGEJO_PR_NUMBER python3 .ci/changelog/pr_field.py
	echo
}
