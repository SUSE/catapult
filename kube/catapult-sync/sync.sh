#!/bin/bash
set -e

CLUSTERS="$(curl $EKCP_HOST| jq -rc '.Clusters[].Name')"
TTY_IMAGE="${TTY_IMAGE:-catapult-wtty}"
ACTIVE_TTYS="$(docker ps --format '{{.Names}}' --filter "name=catapult-wtty")"

echo "Remove dead wttys"
for i in $ACTIVE_TTYS; do
  c=$(echo $i | sed 's/catapult-wtty-//')
  if echo $CLUSTERS | grep -q -v $c;
  then
    docker rm --force $i
  fi
done

echo "Creating new ttys"
v=0
for i in $CLUSTERS; do
  if echo $ACTIVE_TTYS | grep -q -v $i;
  then
  port=$((70+$v))
  echo "Creating tty for $i at $port"
  docker run --name catapult-wtty-$i -d --rm -p 70$port:8080 -e EKCP_HOST=$EKCP_HOST -e CLUSTER_NAME=$i "$TTY_IMAGE"
  fi
  v=$(($v+1))
done