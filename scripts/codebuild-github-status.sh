#!/usr/bin/env bash

# nasty script to interface env vars in codebuild to github-commit-status
# writes whatever status is in $CODEBUILD_BUILD_SUCCEEDING of the env to github, or alternatively argv[1]
# requires $GITHUB_TOKEN to be set to a personal access token with the repo:status oauth scope
# recommend using a bot account for this token

# N.B. the bot must have push access to the repo, or you will receive 404 not found

# https://developer.github.com/v3/repos/statuses/

# @afirth 2018-06

set -euo pipefail

usage(){
	echo "Usage: $0 <context> [error|failure|pending|success]"
	exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

user=afirth
repo=$GITHUB_REPO_NAME
context=$1
url=$("./scripts/codebuild-url-from-arn.pl")

set +u
#getting the status of the build
build_status=$2
#nothing specified in args, get status from codebuild
if [ -z $build_status ]; then
   if [ $CODEBUILD_BUILD_SUCCEEDING ]; then
     build_status=success
   else
     build_status=failure
   fi
fi

# getting the git commit sha - it's only available in the environment in the first step of codepipeline
# if the env var is unset, get it from the file. otherwise, write the file so it's available for the next step.
sha=$CODEBUILD_RESOLVED_SOURCE_VERSION
if [ -z $sha ]; then
  sha=$(cat ./gitsha)
else
  echo $sha > ./gitsha
fi
set -u

#get the helper binary if it doesn't exist
if ! hash github-commit-status 2>/dev/null ; then
curl -fsSL https://github.com/flipgroup/github-commit-status/releases/download/1.0.1/github-commit-status-1.0.1-linux-amd64.tar.gz \
    | tar -xzv -C /usr/local/bin
fi

echo "==> Updating github for $user/$repo:$sha to ${context}: ${build_status} <=="

github-commit-status \
  --user $user \
  --repo $repo \
  --commit $sha \
  --state $build_status \
  --description "$CODEBUILD_INITIATOR on $CODEBUILD_BUILD_IMAGE" \
  --target-url $url \
  --context $context
