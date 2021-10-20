#!/usr/bin/env bash

START_DIR="$PWD"

if [[ -d "./developers" ]]; then

	source ./developers/include-repos.sh

	for REPO in "${REPOS[@]}"; do
		if [[ "${DOCKERHUB_NAME[$REPO]}" != "" ]]; then
			cd $START_DIR;
			cd ..;
			cd $REPO;

      LOCAL_NAME=$(echo "${DOCKERHUB_NAME[$REPO]}" | sed "s/mdscloud\//local\//")

			docker build -t "$LOCAL_NAME:latest" .
		fi
	done

else
	echo "This script is designed to be run from the root of the project. Please change directory back to this location and run the script again."
fi
