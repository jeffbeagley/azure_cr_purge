#!/bin/bash

ACR_NAME="container_registry"
REPO_NAME="repository_name"
TAG_PREFIX="dev-"
TAG_RETENTION=10

# get latest tag
getLatestTag()
{
    az acr repository show-tags -n $ACR_NAME --repository $REPO_NAME --top 1 --orderby time_desc -o tsv

}

# get timestamp of a specific image
getTagTimestamp()
{
    az acr repository show -n $ACR_NAME --image $REPO_NAME:$1 -o tsv | awk '{print $1 }' 

}

LATEST_IMAGE=$(getLatestTag)
LATEST_TAG=(${LATEST_IMAGE//$TAG_PREFIX/ })
OLDER_THAN_TAG=$(( $LATEST_TAG - $TAG_RETENTION ))
OLDER_THAN_DATE=$(getTagTimestamp $TAG_PREFIX$OLDER_THAN_TAG)
QUERY="$TAG_PREFIX$OLDER_THAN"

[[ -z "$OLDER_THAN_DATE" ]] && { echo "$REPO_NAME does not contain $TAG_RETENTION or more tags" ; exit 1; }

echo latest_tag: $LATEST_TAG
echo tags older than $OLDER_THAN_DATE from image $OLDER_THAN_TAG will be deleted

while true; do
    read -p "Are you sure you wish to delete?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# now delete 
echo deleting images...
az acr repository show-manifests -n $ACR_NAME --repository $REPO_NAME --query "[?timestamp<='$OLDER_THAN_DATE'].digest" -o tsv | while read -r digest; do az acr repository delete -n $ACR_NAME --image $REPO_NAME@$digest --yes; done;  
echo 'deleting images complete'