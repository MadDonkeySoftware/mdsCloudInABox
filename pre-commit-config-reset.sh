#!/usr/bin/env sh

MYSQL_ROOT_PASSWORD='pwd4mysqlroot'
MYSQL_USER_PASSWORD='pwd4mysql'
MONGO_ROOT_PASSWORD='pwd4mongo'
MDS_USER_PASS='MDS_SYS_PASSWORD'
BASE64_MDS_USER_PASS='MDS_SYS_PASSWORD'

docker-compose down;

if [ -f ./docker-compose-new.yaml ]; then
    rm -f ./docker-compose-new.yaml
fi

echo 'Configuring the databases with random passwords'
NEW_MDS_IDENTITY_DB_URL="mongodb://dbuser:$MONGO_ROOT_PASSWORD@mongo:27017/mds-identity"
NEW_MDS_FN_MONGO_URL="mongodb://dbuser:$MONGO_ROOT_PASSWORD@mongo:27017"
NEW_MDS_FN_SM_DB_URL="mysql://root:$MYSQL_ROOT_PASSWORD@mysql/mds-sm"
NEW_MDS_FN_SERVER_DB_URL="mysql://dbuser:$MYSQL_USER_PASSWORD@tcp(mysql:3306)/funcs"

awk -f ./mysql-and-mongo-conn.awk \
  -v MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -v MYSQL_USER_PASSWORD=$MYSQL_USER_PASSWORD \
  -v MONGO_PASSWORD=$MONGO_ROOT_PASSWORD \
  -v IDENTITY_DB_URL=$NEW_MDS_IDENTITY_DB_URL \
  -v FN_MONGO_URL=$NEW_MDS_FN_MONGO_URL \
  -v FN_SM_DB_URL=$NEW_MDS_FN_SM_DB_URL \
  -v FN_SERVER_DB_URL=$NEW_MDS_FN_SERVER_DB_URL \
  ./docker-compose.yaml >> ./docker-compose-new.yaml

rm -f ./docker-compose.yaml
mv ./docker-compose-new.yaml ./docker-compose.yaml
echo 'Complete!'

echo 'Updating mongo initialization script...'
awk "\$1 == \"pwd:\" { \$1 = \"  \" \$1; \$2 = \"\\\"\" \"$MONGO_ROOT_PASSWORD\" \"\\\",\" } 1" ./configs/mongo-scripts/mongo-init.js >> ./configs/mongo-scripts/mongo-init-new.js
rm -f ./configs/mongo-scripts/mongo-init.js
mv ./configs/mongo-scripts/mongo-init-new.js ./configs/mongo-scripts/mongo-init.js
echo 'Complete!'

echo 'Attempting to modify your docker-compose.yaml with the new system password'
awk -f ./config-system-user.awk \
  -v MDS_USER_PASS=$MDS_USER_PASS \
  ./docker-compose.yaml >> ./docker-compose-new.yaml

rm -f ./docker-compose.yaml
mv ./docker-compose-new.yaml ./docker-compose.yaml
echo 'Complete!'

echo 'Attempting to update the docker-registry config so it can utilize MDS Cloud notification service'
awk "\$1 == \"Authorization:\" { \$1 = \"        \" \$1; \$3 = \"$BASE64_MDS_USER_PASS]\" } 1" ./configs/docker-registry/config.yml >> ./configs/docker-registry/config-new.yml
rm -f ./configs/docker-registry/config.yml
mv ./configs/docker-registry/config-new.yml ./configs/docker-registry/config.yml
echo 'Complete!'

if [ -f ./docker-compose-new.yaml ]; then
    rm -f ./docker-compose-new.yaml
fi

echo 'Attempting to modify your docker-compose.yaml with standard image references'
awk -f ./developers/to-commit-images.awk \
  ./docker-compose.yaml >> ./docker-compose-new.yaml

rm -f ./docker-compose.yaml
mv ./docker-compose-new.yaml ./docker-compose.yaml
echo 'Complete!'

echo ''
echo 'Local configuration files have been successfully reset.' 
echo ''
