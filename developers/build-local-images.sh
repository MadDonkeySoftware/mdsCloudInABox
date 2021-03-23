#!/usr/bin/env bash

START_DIRECTORY=$(pwd)

PATH_MODIFIER='../..'
if [[ $START_DIRECTORY != *"developers"* ]]; then
  PATH_MODIFIER='..'
fi

echo "Path Modifier: $PATH_MODIFIER"

SOURCE_DIRECTORIES=(
  "mdsCloudIdentity"
  "mdsCloudNotificationService"
  "mdsCloudQueueService"
  "mdsCloudFileService"
  "mdsCloudServerlessFunctions"
  "mdsCloudDockerMinion"
  # "mdsCloudFnProjectMinion"
  "mdsCloudStateMachine"
)

getImageName(){
  case $1 in
    "mdsCloudIdentity")
      echo -n "local/mds-cloud-identity:latest"
      ;;
    "mdsCloudNotificationService")
      echo -n "local/mds-notification-service:latest"
      ;;
    "mdsCloudQueueService")
      echo -n "local/mds-queue-service:latest"
      ;;
    "mdsCloudFileService")
      echo -n "local/mds-file-service:latest"
      ;;
    "mdsCloudServerlessFunctions")
      echo -n "local/mds-serverless-functions:latest"
      ;;
    "mdsCloudFnProjectMinion")
      echo -n "local/mds-fnproject-minion:latest"
      ;;
    "mdsCloudDockerMinion")
      echo -n "local/mds-docker-minion:latest"
      ;;
    "mdsCloudStateMachine")
      echo -n "local/mds-state-machine:latest"
      ;;
    *)
    echo -n "unknown"
    ;;
  esac
}

for SOURCE_DIRECTORY in "${SOURCE_DIRECTORIES[@]}"
do
  if [ ! -d "$PATH_MODIFIER/$SOURCE_DIRECTORY" ]; then
    echo "$SOURCE_DIRECTORY directory does not exist"
    exit 1
  fi
done

cd $PATH_MODIFIER
for SOURCE_DIRECTORY in "${SOURCE_DIRECTORIES[@]}"
do
  echo "Processing: $SOURCE_DIRECTORY"
  IMAGE="$(getImageName $SOURCE_DIRECTORY)"
  if [ "$IMAGE" == "unknown" ]; then
    echo "Could not determine image name for $SOURCE_DIRECTORY"
    exit 1
  fi

  cd "$SOURCE_DIRECTORY"
  docker build -t "$IMAGE" .
  cd ..
done

cd "$START_DIRECTORY"




# echo 'Attempting to modify your docker-compose.yaml with local image references'
# awk -f ./local-images.awk \
#   ./docker-compose.yaml >> ./docker-compose-new.yaml

# rm -f ./docker-compose.yaml
# mv ./docker-compose-new.yaml ./docker-compose.yaml
# echo 'Complete!'