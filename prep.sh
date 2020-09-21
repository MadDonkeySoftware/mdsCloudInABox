#!/usr/bin/env sh

MYSQL_ROOT_PASSWORD='pwd4mysqlroot'
MONGO_ROOT_PASSWORD='pwd4mongo'

echo 'Pulling all dependent images to make the rest of the process quicker'
docker-compose pull;
docker-compose build;

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
openssl req -x509 -nodes -days 365 -newkey rsa:2048 --keyout nginx-selfsigned.key -out nginx-selfsigned.crt -batch
mkdir -p ./configs/mds-identity-proxy
cp -f ./nginx-selfsigned.crt ./configs/mds-identity-proxy
cp -f ./nginx-selfsigned.key ./configs/mds-identity-proxy
rm -f ./nginx-selfsigned.crt ./nginx-selfsigned.key
echo 'Complete!'

echo 'Initializing MongoDB...'
docker-compose up -d mongo;
sleep 5;
docker exec mdscloudinabox_mongo_1 mongo -u dbuser -p $MONGO_ROOT_PASSWORD /var/scripts/mongo-init.js;
echo 'Complete!'

echo 'Starting the identity service so you can capture the root password.'
docker-compose up -d mds-identity;
sleep 30;
MDS_USER_PASS=$(docker logs mdscloudinabox_mds-identity_1 2>&1 | grep password | sed -n 's/^.*password":"\(\S*\)","msg".*$/\1/p')
echo 'Complete!'

docker-compose down;

echo 'Attempting to modify your docker-compose.yaml with the new system password'
awk "\$1 == \"MDS_SM_SYS_PASSWORD:\" || \$1 == \"MDS_FN_SYS_PASSWORD:\" { \$1 = \"      \" \$1; \$2 = \"\\\"$MDS_USER_PASS\\\"\" } 1" ./docker-compose.yaml >> ./docker-compose-new.yaml
rm -f ./docker-compose.yaml
mv ./docker-compose-new.yaml ./docker-compose.yaml
echo 'Complete!'

echo 'Attempting to update the docker-registry config so it can utilize MDS Cloud notification service'
BASE64_MDS_USER_PASS=$(echo -n "mdsCloud:$MDS_USER_PASS" | base64 )
awk "\$1 == \"Authorization:\" { \$1 = \"        \" \$1; \$3 = \"$BASE64_MDS_USER_PASS]\" } 1" ./configs/docker-registry/config.yml >> ./configs/docker-registry/config-new.yml
rm -f ./configs/docker-registry/config.yml
mv ./configs/docker-registry/config-new.yml ./configs/docker-registry/config.yml
echo 'Complete!'

echo ''
echo '  ===================================='
echo '  ==== Your Auto-configured items ===='
echo '  ===================================='
echo "  The mysql root password is \"$MYSQL_ROOT_PASSWORD\""
echo "  The mongo root password is \"$MONGO_ROOT_PASSWORD\""
echo "  mdsCloud password is \"$MDS_USER_PASS\""
echo "  The base64 encoded credentials are \"$BASE64_MDS_USER_PASS\""
echo ''
echo 'Running "git diff" will allow you to verify the auto configuration script.'
echo 'If any values are blank please fully tear down the environment with the'
echo 'command "docker-compose down -v" then re-run the prep script.'
echo ''
echo "If you are using the MDS CLI don't forget to update any appropriate"
echo 'environtment configuraitons!'
echo "Ex: mds config --env localAdmin write password $MDS_USER_PASS"
echo ''