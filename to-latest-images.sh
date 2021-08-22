#!/usr/bin/env sh

if [ -f ./docker-compose-new.yaml ]; then
    rm -f ./docker-compose-new.yaml
fi

echo 'Attempting to modify your docker-compose.yaml with latest image references'
awk -f ./developers/to-latest-images.awk \
  ./docker-compose.yaml >> ./docker-compose-new.yaml

rm -f ./docker-compose.yaml
mv ./docker-compose-new.yaml ./docker-compose.yaml
echo 'Complete!'