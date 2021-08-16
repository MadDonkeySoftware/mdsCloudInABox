#!/usr/bin/env bash

VERSION="$1"
START_DIR="$PWD"

# Declare all the repos we care about
declare -a REPOS=(
	"mdsCloudCli"
	"mdsCloudDockerMinion"
	"mdsCloudDocs"
	"mdsCloudFileService"
	"mdsCloudIdentity"
	"mdsCloudNotificationService"
	"mdsCloudQueueService"
	"mdsCloudSampleApp"
	"mdsCloudSdkNode"
	"mdsCloudServerlessFunctions"
	"mdsCloudStateMachine"
)

declare -A DOCKERHUB_NAME=(
	["mdsCloudCli"]=""  # no container
	["mdsCloudDockerMinion"]="mdscloud/mds-docker-minion"
	["mdsCloudDocs"]=""  # no container
	["mdsCloudFileService"]="mdscloud/mds-file-service"
	["mdsCloudIdentity"]="mdscloud/mds-cloud-identity"
	["mdsCloudNotificationService"]="mdscloud/mds-notification-service"
	["mdsCloudQueueService"]="mdscloud/mds-queue-service"
	["mdsCloudSampleApp"]=""  # no container
	["mdsCloudSdkNode"]=""  # no container
	["mdsCloudServerlessFunctions"]="mdscloud/mds-serverless-functions"
	["mdsCloudStateMachine"]="mdscloud/mds-state-machine"
)

if [[ "$VERSION" == "" ]]; then
	echo "Version argument must be supplied"
	exit 1
fi

if [[ -f "./README.md" ]]; then

	# First ensure that all repos do not have any changes before starting the release
	for REPO in "${REPOS[@]}"; do
		if [[ "${DOCKERHUB_NAME[$REPO]}" != "" ]]; then
			# echo "$REPO"
			# echo "${DOCKERHUB_NAME[$REPO]}"

			cd $START_DIR;
			cd ..;
			cd $REPO;

			HAS_CHANGES=$(git status --porcelain=v1 2>/dev/null | wc -l)
			if [[ "$HAS_CHANGES" != "0" ]]; then
				echo "$REPO appears to have changes. Cannot create release"
				exit 1
			fi
		fi
	done

	# If we got this far then our checks passed. Go with creating the release.
	for REPO in "${REPOS[@]}"; do
		if [[ "${DOCKERHUB_NAME[$REPO]}" != "" ]]; then
			cd $START_DIR;
			cd ..;
			cd $REPO;

			docker build -t "${DOCKERHUB_NAME[$REPO]}:latest ."
			docker build -t "${DOCKERHUB_NAME[$REPO]}:${VERSION} ."
			docker push "${DOCKERHUB_NAME[$REPO]}:latest"
			docker push "${DOCKERHUB_NAME[$REPO]}:${VERSION}"

			# TODO: Include stable tag

			git tag -a "v$VERSION" -m "Push of version $VERSION to docker hub"
			git push upstream --tags
		fi
	done
else
	echo "This script is designed to be run from the root of the project. Please change directory back to this location and run the script again."
fi


