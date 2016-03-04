#!/bin/bash

source ./migrate.conf

getAllAccounts() {
  curl -s --user \
  	"$SOURCE_DTR_ADMIN":"$SOURCE_DTR_PASSWORD" --insecure \
  	https://"$SOURCE_DTR_DOMAIN"/api/v0/repositories | \
  		jq '.repositories[] | { (.namespaceType):(.namespace)  }' | grep -v '[{}]' | grep -v admin
}

getAllRepos() {
  curl -s --user \
  	"$SOURCE_DTR_ADMIN":"$SOURCE_DTR_PASSWORD" --insecure \
  	https://"$SOURCE_DTR_DOMAIN"/api/v0/repositories | \
  		jq '.repositories[] | {  (.namespace):(.name) }' | grep -v '[{}]' | sed -e 's/:\s*/\//' -e 's/"//g' 
}

getTagsPerRepo() {
  curl -s --user \
  	"$SOURCE_DTR_ADMIN":"$SOURCE_DTR_PASSWORD" --insecure \
  	https://"$SOURCE_DTR_DOMAIN"/api/v0/repositories/${1}/tags | \
          jq '. | { (.name): .tags[].name }' | grep -v '[{}]' | sed 's/[" ]//g'
}

pullImages() {
  for i in `getAllTags`
    do
     docker pull $SOURCE_DTR_DOMAIN/$i 
     docker tag $SOURCE_DTR_DOMAIN/$i $DEST_DTR_DOMAIN/$i ;
   done
}

createNameSpaces() {
  for i in `getAllAccounts`
    do
      sed 's/^\s*"\(.*\)":\s*"\(.*\)"/{"type": "\1", "name": "\2" }/' /var/tmp/accounts > /var/tmp/dest_accounts
    done
  IFS=
  cat /var/tmp/dest_accounts | sort -u | while IFS= read -r i;
    do
      curl --insecure --user admin:Admin123 -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "X-Csrf-Token: lCag0CgWAlVzYuTNCinQbbDYqvfo2b6-W1zpvyY52S0="  -d "$i" https://"$DEST_DTR_DOMAIN"/api/v0/accounts
    done
}
      
getAllTags() {
  for i in `getAllRepos`
    do
      getTagsPerRepo $i
    done
}

getAllRepos
pullImages
getAllAccounts > /var/tmp/accounts
createNameSpaces