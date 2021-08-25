# Declare all the repos we care about
declare -a REPOS=(
	"mdsCloudCli"
	"mdsCloudDockerMinion"
	"mdsCloudDocs"
	"mdsCloudFileService"
	"mdsCloudIdentity"
	"mdsCloudNotificationService"
	"mdsCloudQueueService"
	"mdsCloudSampleApp"
	"mdsCloudSdkNode"
	"mdsCloudSdkGo"
	"mdsCloudServerlessFunctions"
	"mdsCloudStateMachine"
	"mdsCloudTerraformProvider"
)

# Map them to their corresponding docker container names
declare -A DOCKERHUB_NAME=(
	["mdsCloudDockerMinion"]="mdscloud/mds-docker-minion"
	["mdsCloudFileService"]="mdscloud/mds-file-service"
	["mdsCloudIdentity"]="mdscloud/mds-cloud-identity"
	["mdsCloudNotificationService"]="mdscloud/mds-notification-service"
	["mdsCloudQueueService"]="mdscloud/mds-queue-service"
	["mdsCloudServerlessFunctions"]="mdscloud/mds-serverless-functions"
	["mdsCloudStateMachine"]="mdscloud/mds-state-machine"
)

# Append to GOPATH env variable if it exists.
declare -A GOLANG_PATH_FRAGMENT=(
	["mdsCloudSdkGo"]="/src/github.com/MadDonkeySoftware/mdsCloudSdkGo"
	["mdsCloudTerraformProvider"]="/src/github.com/MadDonkeySoftware/mdsCloudTerraformProvider"
)