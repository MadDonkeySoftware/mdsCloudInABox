# Development Quick Start

## Prerequisites

The following components must be installed and available on the system to
interact with MDS Cloud in-a-box. Feel free to install these items via their
direct links or your package manager of choice. If you can run `docker-compose`,
`node`, and `mds` from your command line you should be ready to run the run-book
below.

* [Docker Compose](https://docs.docker.com/compose/) installed.
* [Node and NPM](https://nodejs.org)
* [MDS CLI](https://github.com/MadDonkeySoftware/mdsCloudCli) installed.
  * Only the NPM link section as of this writing.

## Run-book
* (Optional) `docker-compose pull`
  * This will pull all images down to the local system in preparation for
    configuring the environment
* `./prep.sh`
  * Walks the user through configuration of various parts of the system.
* Create the required system items below (using the credentials captured during
  `./prep.sh` run)
  * If this step fails with a "unexpected EOF while parsing" see troubleshooting
    below
* Adjust system & various configs
  * Allow insecure docker registries (see troubleshooting area)
* `docker-compose up`
  * Starts the system so the user can begin interacting with it.
* (Optional) Create the required system items if you will be working with
  serverless functions or any functionality that is dependent upon serverless
  functions.
  * Note: The commands for these can be found at the end of `./prep.sh` output
* (Optional) Configure your MDS CLI with with `local` and `localAdmin`
  environments
* Do whatever work/exploration you're going to do.
* Stop and optionally cleanup your system.
  * Running the cleanup will remove all container volumes. This means that data
    stored through the containers will need to be re-created next time you run.
    Conversely if you omit cleanup the data created while running mdsCloud will
    be available next time you run `docker-compose up`. Use `ctrl-c` to stop
    docker compose.
  * If you run docker compose detached, with the `-d` option, you can use the
    following commands to stop the container suite
    * Stop w/o cleanup - `docker-compose down`
    * Stop w/ cleanup - `docker-compose down -v`

# Required System Items

Note that the commands below assume you have already installed and configured
the MDS CLI with an environment named `localAdmin`.

* Queue Service
  * mdsCloudServerlessFunctions-FnProjectWork
    * `mds qs create --env localAdmin mdsCloudServerlessFunctions-FnProjectWork`
  * mdsCloudServerlessFunctions-FnProjectWork-dlq
    * `mds qs create --env localAdmin mdsCloudServerlessFunctions-FnProjectWork-dlq`
  * mds-sm-pendingQueue
    * `mds qs create --env localAdmin mds-sm-pendingQueue`
  * mds-sm-inFlightQueue
    * `mds qs create --env localAdmin mds-sm-inFlightQueue`
* File Service
  * mdsCloudServerlessFunctionsWork
    * `mds fs create --env localAdmin mdsCloudServerlessFunctionsWork`

# Development Full Setup

Before running the items in the full setup area the quick start instructions
should be completed. The full setup instructions are mainly geared towards
getting additional items configured such as the ELK stack logging.

## Create your development user

```sh
curl --insecure --request POST 'https://localhost:8081/v1/register' \
--header 'Content-Type: application/json' \
--data-raw '{
    "userId": "my-user",
    "email": "no@no.com",
    "password": "password",
    "friendlyName": "Local Developer",
    "accountName": "Local Development Account"
}'
```

## Configure MDS CLI environments

Run the `mds config --env local wizard` command to configure the local
environment. Once complete the `--env local` can be replaced with
`--env localAdmin` to configure the local administrator environment for the CLI.

A quick description of prompts given and mdsCloudInABox default URLs.

| Prompt                   | Description                                         |
|--------------------------|-----------------------------------------------------|
| Account                  | The account number returned after registering.      |
| User ID                  | The user id to be used with the system.             |
| Password                 | The password associated with the above user.        |
| Identity Service URL     | `https://127.0.0.1:8081`                            |
| Allow self signed certs. | `Y` since local uses an un-trusted self-signed cert |
| Notification Service URL | `http://127.0.0.1:8082`                             |
| Queue Service URL        | `http://127.0.0.1:8083`                             |
| File Service URL         | `http://127.0.0.1:8084`                             |
| Serverless Function URL  | `http://127.0.0.1:8085`                             |
| State Machine URL        | `http://127.0.0.1:8086`                             |


## Configure Kibana to view logs

* Log in to the [Kibana UI](http://localhost:5601)
  * User: elastic
  * Password: changeme
* Use the left nav to go to the "Logs" section
* Click the "Settings" tab
* Under Indices, update the "Log Indices" field to include "logstash-*"
  * Ex: `filebeat-*,kibana_sample_data_logs*,logstash-*`
* Under Log Columns
  * Remove line with "Field"
  * Add Column, search for item "name".
  * Optionally drag "Message" field to bottom to make logs easier to read
* Optionally, it may be prudent to familiarize yourself with the
[Kibana Query Language](https://www.elastic.co/guide/en/kibana/current/kuery-query.html)

## Allowing mdsCloud to use insecure docker registry

MDS Cloud in a box uses an insecure docker registry to quickly get users up and
running. The IP addresses used by docker are in a "non-routable" IP range for
added safety. Since MDS uses your local systems docker instance by passing the
docker socket into the container that need it you will need to configure your
systems docker instance to allow insecure registries.

### Required changes

* edit the `/etc/docker/daemon.json` on your host system.
  * If this file does not exist, create it.
* add/edit the below code block
  * The below networks are CIDR notation of the IPv4 non-routable address spaces
* restart docker

```
{
  "insecure-registries": [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}
```

# Further Reading

## Configuring ELK authentication

See [the documentation](https://github.com/deviantony/docker-elk#initial-setup)
on their github.

## Troubleshooting

### Running prep.sh has output "unexpected EOF while parsing"

This is typically because the mongo database already has a system user
configured when mdsCloud identity attempts to create the system user. One can
start and connect to the mongo instance and remove the user from the collection
manually. When the system user is re-created the password will be output to the
logs.

Step by step instructions:

* `docker-compose up -d mongo`
* `docker exec -it mdscloudinabox_mongo_1 mongo -u dbuser -p pwd4mongo`
  * you should now be in a mongo shell
  * `use mds-identity`
  * `db.mdsUser.remove({ "friendlyName": "System User" })`
  * `exit`
* `docker-compose stop`

Now you should be able to run `docker-compose up` as normal and inspect the
output to recover the password. The output line should begin with
"mds-identity_1". Once you recover the password do not forget to update the
docker compose definition with the new password.


## Other Useful Information

* Removing all orphaned docker images
  * `docker rmi $(docker images | grep '<none>' | awk '{print $3}')`