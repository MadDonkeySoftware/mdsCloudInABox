#!/usr/bin/env bash

# TODO: Add clone mode and origin user support
CLONE_MODE="$1"
ORIGIN_USER="$2"
START_DIR="$PWD"

# Declare all the repos we care about
declare -a REPOS=(
	"mdsCloudDocs"
	"mdsCloudSdkNode"
	"mdsCloudCli"
	"mdsCloudFileService"
	"mdsCloudFnProjectMinion"
	"mdsCloudIdentity"
	"mdsCloudNotificationService"
	"mdsCloudQueueService"
	"mdsCloudServerlessFunctions"
	"mdsCloudServerlessFunctions-sampleApp"
	"mdsCloudStateMachine"
)

if [[ -f "./README.md" ]]; then
	for REPO in "${REPOS[@]}"; do
		cd $START_DIR;
		if [ ! -d "../$REPO" ]; then
			echo "Checkout $REPO"
			cd ..;
			git clone -o upstream git@github.com:MadDonkeySoftware/$REPO.git
			cd $REPO;
			npm i;
		else
			echo "Skipping checkout of $REPO"
		fi
	done
else
	echo "This script is designed to be run from the root of the project. Please change directory back to this location and run the script again."
fi


