#!/bin/bash

ARTIFACTS_GROUP=$1
MAX_PREVIOUS_VERSIONS=$2
M2_REPO_PATH=/var/lib/jenkins/.m2/repository
BASE_PATH=${M2_REPO_PATH}/${ARTIFACTS_GROUP}

typeset -a artifact_groups=$(find ${BASE_PATH}/* -maxdepth 0 -type d )
for artifact_path in $artifact_groups; do
  artifact=${artifact_path##*/}
  echo "$(date "+%b %d %H:%M:%S") Scanning $artifact"
  typeset -a artifact_versions=( $(find ${artifact_path}/* -maxdepth 1 -type d|sort --version-sort) )
  set -- ${artifact_versions[*]}
  typeset -i artifact_versions_qty=$#

  echo "$(date "+%b %d %H:%M:%S") Found $artifact_versions_qty versions"
  if [ $artifact_versions_qty -le 5 ]; then continue; fi
  ((artifacts_purge_range = $artifact_versions_qty - $MAX_PREVIOUS_VERSIONS))

  for ((i=0; i<$artifacts_purge_range; ++i)); do
    echo "$(date "+%b %d %H:%M:%S") Attempting to purge ${artifact_versions[$i]}"
    if [[ ${artifact_versions[$i]} =~ m2/repository ]]; then
      rm -rf ${artifact_versions[$i]}
    fi
  done
done
echo "$(date "+%b %d %H:%M:%S") Done"