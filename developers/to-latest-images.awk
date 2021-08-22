$1 == "image:" && $2 == "mdscloud/mds-cloud-identity:stable" { $1 = "    " $1; $2 = "mdscloud/mds-cloud-identity:latest" }
$1 == "image:" && $2 == "mdscloud/mds-notification-service:stable" { $1 = "    " $1; $2 = "mdscloud/mds-notification-service:latest" }
$1 == "image:" && $2 == "mdscloud/mds-queue-service:stable" { $1 = "    " $1; $2 = "mdscloud/mds-queue-service:latest" }
$1 == "image:" && $2 == "mdscloud/mds-file-service:stable" { $1 = "    " $1; $2 = "mdscloud/mds-file-service:latest" }
$1 == "image:" && $2 == "mdscloud/mds-serverless-functions:stable" { $1 = "    " $1; $2 = "mdscloud/mds-serverless-functions:latest" }
$1 == "image:" && $2 == "mdscloud/mds-docker-minion:stable" { $1 = "    " $1; $2 = "mdscloud/mds-docker-minion:latest" }
$1 == "image:" && $2 == "mdscloud/mds-state-machine:stable" { $1 = "    " $1; $2 = "mdscloud/mds-state-machine:latest" }
$1 == "image:" && $2 == "mdscloud/mds-docker-minion:stable" { $1 = "    " $1; $2 = "mdscloud/mds-docker-minion:latest" }
1 # Prints the current line (modified)