#!/usr/bin/env bash

START_DIR="$PWD"

if [[ -d "./developers" ]]; then

	source ./developers/include-repos.sh

	# First ensure that all repos are in a good state before attempting release
	SHOULD_EXIT=0
	for REPO in "${REPOS[@]}"; do
		if [[ "${DOCKERHUB_NAME[$REPO]}" != "" ]]; then
			# Check that docker image for latest exists
			HAS_LOCAL_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "${DOCKERHUB_NAME[$REPO]}:latest" | wc -l)
			if [[ "$HAS_LOCAL_IMAGE" != "1" ]]; then
				echo "$REPO does not appear to have the latest image tag: ${DOCKERHUB_NAME[$REPO]}:latest"
				SHOULD_EXIT=1
			fi
		fi
	done

	if [[ $SHOULD_EXIT == 1 ]]; then
		exit 1
	fi

	# If we got this far then our checks passed. Go with creating the release.
	for REPO in "${REPOS[@]}"; do
		if [[ "${DOCKERHUB_NAME[$REPO]}" != "" ]]; then
			docker tag "${DOCKERHUB_NAME[$REPO]}:latest" "${DOCKERHUB_NAME[$REPO]}:stable"
			docker push "${DOCKERHUB_NAME[$REPO]}:stable"
		fi
	done

	echo "#####"
	echo "# All stable images have been pushed successfully."
	echo "#####"
else
	echo "This script is designed to be run from the root of the project. Please change directory back to this location and run the script again."
fi
