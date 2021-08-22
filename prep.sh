#!/usr/bin/env sh

# With special characters
# MYSQL_ROOT_PASSWORD=$(tr -dc '(\&\_a-zA-Z0-9\^\*\@' < /dev/urandom | head -c 32)
# MYSQL_USER_PASSWORD=$(tr -dc '(\&\_a-zA-Z0-9\^\*\@' < /dev/urandom | head -c 32)
# MONGO_ROOT_PASSWORD=$(tr -dc '(\&\_a-zA-Z0-9\^\*\@' < /dev/urandom | head -c 32)
# MDS_USER_PASS=$(tr -dc '(\&\_a-zA-Z0-9\^\*\@' < /dev/urandom | head -c 32)

# Without special characters
MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
MYSQL_USER_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
MONGO_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
MDS_USER_PASS=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)

docker-compose down -v;
docker-compose build;

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

docker-compose up -d mysql;
echo 'Sleeping a bit to let mysql fully init. There is no way to know a exact time'
echo 'to sleep as it is dependent upon the system and current load. '
sleep 15;
docker exec -it mdscloudinabox_mysql_1 mysql -p"$MYSQL_ROOT_PASSWORD" -e "source /var/scripts/mysql-init-script.sql";

echo 'Configuring SSH keys for mdsCloudIdentity...'
echo 'foobarbaz' > pass
rm -f ./key ./key.pub ./key.pub.pem
ssh-keygen -f ./key -t rsa -b 4096 -m PEM -n $(cat pass) -N 'some-pass'
ssh-keygen -f ./key.pub -e -m pem > key.pub.pem
mkdir -p ./configs/mds-identity
cp -f ./key ./configs/mds-identity
cp -f ./key.pub ./configs/mds-identity
cp -f ./key.pub.pem ./configs/mds-identity
cp -f ./pass ./configs/mds-identity
rm -f ./key ./key.pub ./key.pub.pem ./pass
echo 'Complete!'

# https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04
echo 'Configuring SSH keys for mdsCloudIdentity proxy...'
rm -f ./nginx-selfsigned.crt ./nginx-selfsigned.key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx-selfsigned.key -out nginx-selfsigned.crt -batch -subj /
mkdir -p ./configs/mds-identity-proxy
cp -f ./nginx-selfsigned.crt ./configs/mds-identity-proxy
cp -f ./nginx-selfsigned.key ./configs/mds-identity-proxy
rm -f ./nginx-selfsigned.crt ./nginx-selfsigned.key
echo 'Complete!'

echo 'Updating mongo initialization script...'
awk "\$1 == \"pwd:\" { \$1 = \"  \" \$1; \$2 = \"\\\"\" \"$MONGO_ROOT_PASSWORD\" \"\\\",\" } 1" ./configs/mongo-scripts/mongo-init.js >> ./configs/mongo-scripts/mongo-init-new.js
rm -f ./configs/mongo-scripts/mongo-init.js
mv ./configs/mongo-scripts/mongo-init-new.js ./configs/mongo-scripts/mongo-init.js
echo 'Complete!'

echo 'Initializing MongoDB...'
docker-compose up -d mongo;
sleep 5;
docker exec mdscloudinabox_mongo_1 mongo -u dbuser -p $MONGO_ROOT_PASSWORD /var/scripts/mongo-init.js;
echo 'Complete!'

echo 'Attempting to modify your docker-compose.yaml with the new system password'
awk -f ./config-system-user.awk \
  -v MDS_USER_PASS=$MDS_USER_PASS \
  ./docker-compose.yaml >> ./docker-compose-new.yaml

rm -f ./docker-compose.yaml
mv ./docker-compose-new.yaml ./docker-compose.yaml
echo 'Complete!'

echo 'Starting the identity service so root system user password can be assigned.'
docker-compose up -d mds-identity;
sleep 30;
# MDS_USER_PASS=$(docker logs mdscloudinabox_mds-identity_1 2>&1 | grep password | sed -n 's/^.*password":"\(\S*\)","msg".*$/\1/p')
echo 'Complete!'

docker-compose down;

echo 'Attempting to update the docker-registry config so it can utilize MDS Cloud notification service'
BASE64_MDS_USER_PASS=$(echo -n "mdsCloud:$MDS_USER_PASS" | base64 )
awk "\$1 == \"Authorization:\" { \$1 = \"        \" \$1; \$3 = \"$BASE64_MDS_USER_PASS]\" } 1" ./configs/docker-registry/config.yml >> ./configs/docker-registry/config-new.yml
rm -f ./configs/docker-registry/config.yml
mv ./configs/docker-registry/config-new.yml ./configs/docker-registry/config.yml
echo 'Complete!'

EXISTS=$(command -v "mds")

if [ "$EXISTS" = "" ]; then
  echo 'WARNING: Could not verify your mds CLI install. Automated configuation of the local and localAdmin environments requires the mds CLI to be installed. Skipping configuation.'
else
  IS_LOCAL_ENV_SETUP=$(mds env list | grep '^local$' | wc -l)
  IS_LOCAL_ADMIN_ENV_SETUP=$(mds env list | grep '^localAdmin$' | wc -l)

  mkdir -p ~/.mds

  if [ "$IS_LOCAL_ENV_SETUP" = "0" ]; then
    echo 'Creating mds CLI "local" environment'
    echo '{"account": "1001","userId":"myUser","password":"password","identityUrl":"https://127.0.0.1:8081","nsUrl":"http://127.0.0.1:8082","qsUrl":"http://127.0.0.1:8083","fsUrl":"http://127.0.0.1:8084","sfUrl":"http://127.0.0.1:8085","smUrl":"http://127.0.0.1:8086","allowSelfSignCert":true}' >> ~/.mds/local.json
  fi

  if [ "$IS_LOCAL_ADMIN_ENV_SETUP" = "0" ]; then
    echo 'Creating mds CLI "localAdmin" environment'
    echo '{"account": "1","userId":"mdsCloud","password":"password","identityUrl":"https://127.0.0.1:8081","nsUrl":"http://127.0.0.1:8082","qsUrl":"http://127.0.0.1:8083","fsUrl":"http://127.0.0.1:8084","sfUrl":"http://127.0.0.1:8085","smUrl":"http://127.0.0.1:8086","allowSelfSignCert":true}' >> ~/.mds/localAdmin.json
  fi
fi

echo "
  ====================================
  ==== Your Auto-configured items ====
  ====================================
  The mysql root password is $MYSQL_ROOT_PASSWORD
  The mysql user password is $MYSQL_USER_PASSWORD
  The mongo root password is $MONGO_ROOT_PASSWORD
  mdsCloud password is $MDS_USER_PASS
  The base64 encoded credentials are $BASE64_MDS_USER_PASS" > ./development-passwords.txt

cat ./development-passwords.txt
echo ''
echo 'Running "git diff" will allow you to verify the auto configuration script.'
echo 'If any values are blank please fully tear down the environment with the'
echo 'command "docker-compose down -v" then re-run the prep script. If you need'
echo 'to reference these passwords later a file named "development-passwords.txt"'
echo 'has been created for you in this directory.'
echo ''
echo "If you are using the MDS CLI don't forget to update any appropriate"
echo 'environtment configuraitons!'
echo "Ex: mds config --env localAdmin write password $MDS_USER_PASS"
echo ''
echo 'Once your MDS CLI administrator config is updated and the docker-compose env.'
echo 'is running, create the appropriate system level items. You may need to remove '
echo 'your mds credential cache located at ~/.mds/cache if you encounter errors.'
echo ''
echo 'mds qs create --env localAdmin mdsCloudServerlessFunctions-FnProjectWork'
echo 'mds qs create --env localAdmin mdsCloudServerlessFunctions-FnProjectWork-dlq'
echo 'mds qs create --env localAdmin mds-sm-pendingQueue'
echo 'mds qs create --env localAdmin mds-sm-inFlightQueue'
echo 'mds fs create --env localAdmin mdsCloudServerlessFunctionsWork'
echo ''
