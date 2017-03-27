#!/bin/bash

BASE_GROUP=com/ath/$1
MAX_PREVIOUS_VERSION=$2
MAX_SNAPSHOT_BUILDS=8
M2_REPO_PATH=/var/lib/jenkins/.m2/repository
BASE_PATH=${M2_REPO_PATH}/${BASE_GROUP}

typeset -a artifact_groups=$(find ${BASE_PATH}/* -maxdepth 0 -type d )
for artifact_path in $artifact_groups; do
  artifact=${artifact_path##*/}
  echo "$(date "+%b %d %H:%M:%S") Scanning $artifact"
  typeset -a artifact_versions=( $(find ${artifact_path}/* -maxdepth 1 -type d|sort --version-sort) )
  set -- ${artifact_versions[*]}
  typeset -i artifact_versions_qty=$#

  echo "$(date "+%b %d %H:%M:%S") Found $artifact_versions_qty versions"
  if [ $artifact_versions_qty -le 5 ]; then
    for artifact in "${artifact_versions[@]}"; do
      if [[ $artifact =~ SNAPSHOT ]]; then
        typeset -a snapshot_builds=( $(find $artifact/* -maxdepth 1 -type f -name '*.jar' -o -name '*.war' -o -name '*.ear') )
        set -- ${snapshot_builds[*]}
        typeset -i snapshot_builds_qty=$#
        if [[ $snapshot_builds_qty -gt $MAX_SNAPSHOT_BUILDS ]]; then
          echo "Found $snapshot_builds_qty snapshot builds"
          ((build_purge_range = $snapshot_builds_qty - $MAX_SNAPSHOT_BUILDS))
          for ((i=0; i<$build_purge_range; ++i)); do
            echo "$(date "+%b %d %H:%M:%S") Attempting to purge ${snapshot_builds[$i]}"
            if [[ ${snapshot_builds[$i]} =~ m2/repository ]]; then
              rm -rf ${snapshot_builds[$i]}
              rm -rf ${snapshot_builds[$i]}.sha1
              rm -rf ${snapshot_builds[$i]::-3}pom
              rm -rf ${snapshot_builds[$i]::-3}pom.sha1
            fi
          done
        fi
      fi
    done
  else
    ((artifacts_purge_range = $artifact_versions_qty - $MAX_PREVIOUS_VERSION))
    for ((i=0; i<$artifacts_purge_range; ++i)); do
      echo "$(date "+%b %d %H:%M:%S") Attempting to purge ${artifact_versions[$i]}"
      if [[ ${artifact_versions[$i]} =~ m2/repository ]]; then
        rm -rf ${artifact_versions[$i]}
      fi
    done
  fi
done
echo "$(date "+%b %d %H:%M:%S") Done"
