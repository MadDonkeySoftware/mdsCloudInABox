#!/usr/bin/env bash

#####
# The intent of this script is to create builds for every MDSCloud service with the same version number. This will allow operators
# in the future to shift from version to version without needing to cross-reference which versions have been tested together. It
# has been accepted that there will be multiple versions of some services with the same version number and underlying code.
#####

VERSION="$1"
START_DIR="$PWD"

GIT_TAG="mds-release-v$VERSION"

if [[ "$VERSION" == "" ]]; then
	echo "Version argument must be supplied"
	exit 1
fi

if [[ -d "./developers" ]]; then

	source ./developers/include-repos.sh

	# First ensure that all repos are in a good state before attempting release
	SHOULD_EXIT=0
	for REPO in "${REPOS[@]}"; do
		if [[ "${GOLANG_PATH_FRAGMENT[$REPO]}" != "" ]]; then
			if [[ "$GOPATH" != "" ]]; then
				cd $START_DIR;
				cd "$GOPATH${GOLANG_PATH_FRAGMENT[$REPO]}";
			else
				echo "Cannot verify golang repository $REPO. GOPATH environment variable not found"
				SHOULD_EXIT=1
				continue
			fi
		else
			cd $START_DIR;
			cd ..;
			cd $REPO;
		fi

		# Check to make sure there are no changes to the soruce
		HAS_CHANGES=$(git status --porcelain=v1 2>/dev/null | wc -l)
		if [[ "$HAS_CHANGES" != "0" ]]; then
			echo "$REPO appears to have changes. Cannot create release"
			SHOULD_EXIT=1
		fi

		# Ensure we are on the master branch
		BRANCH_NAME=$(git branch --show-current)
		if [[ "$BRANCH_NAME" != "master" && "$BRANCH_NAME" != "main" ]]; then
			echo "$REPO appears to not be on the master/main branch. Branch detected as $BRANCH_NAME"
			SHOULD_EXIT=1
		fi

		# Check if tag already exists
		HAS_EXISTING_TAG=$(git tag -l | grep "$GIT_TAG" | wc -l)
		if [[ "$HAS_EXISTING_TAG" != "0" ]]; then
			echo "$REPO appears to already have the tag $GIT_TAG."
			SHOULD_EXIT=1
		fi
	done

	if [[ $SHOULD_EXIT == 1 ]]; then
		exit 1
	fi

	# echo "All checks passed"
	# read -p "Are you ready to create the release? [y/N] " READY_TO_PROCEED # echo "$READY_TO_PROCEED"

	# If we got this far then our checks passed. Go with creating the release.
	for REPO in "${REPOS[@]}"; do
		if [[ "${GOLANG_PATH_FRAGMENT[$REPO]}" != "" ]]; then
			cd $START_DIR;
			cd "$GOPATH${GOLANG_PATH_FRAGMENT[$REPO]}";
		else
			cd $START_DIR;
			cd ..;
			cd $REPO;
		fi

		if [[ "${DOCKERHUB_NAME[$REPO]}" != "" ]]; then
			docker build -t "${DOCKERHUB_NAME[$REPO]}:latest" .
			docker tag "${DOCKERHUB_NAME[$REPO]}:latest" "${DOCKERHUB_NAME[$REPO]}:${VERSION}"
			docker push "${DOCKERHUB_NAME[$REPO]}:latest"
			docker push "${DOCKERHUB_NAME[$REPO]}:${VERSION}"
		fi

		git tag -a "$GIT_TAG" -m "Push of version $VERSION to docker hub"
		git push upstream --tags
	done
else
	echo "This script is designed to be run from the root of the project. Please change directory back to this location and run the script again."
fi


