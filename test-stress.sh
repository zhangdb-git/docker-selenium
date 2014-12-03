#!/bin/bash

BROWSER=$1
FOLDER=$2

NODE_COUNT=10
REPEATER_COUNT=20
TESTS_PER_REPEATER=10

if [ -z $BROWSER ]; then
  BROWSER=chrome
fi

if [ -z $FOLDER ]; then
  FOLDER=stress-logs
fi

echo Building test container image
docker build -t selenium/test:local ./Test

echo Building test metrics image
docker build -t selenium/metrics:local ./Metrics

rm -rf $FOLDER
mkdir $FOLDER

echo Starting Hub
HUB=$(docker run -d selenium/hub:2.44.0)
HUB_NAME=$(docker inspect -f '{{ .Name  }}' $HUB | sed s:/::)
docker logs -t -f $HUB > $FOLDER/hub.log 2>&1 &
sleep 2

declare -a NODES

INDEX=0
while [ $INDEX -lt $NODE_COUNT ]; do
  echo Starting Node $INDEX
  NODE=$(docker run -d --link $HUB_NAME:hub selenium/node-$BROWSER:2.44.0)
  NODE_METRICS=$(docker run -d -v /sys/fs/cgroup/memory/docker:/metrics selenium/metrics:local $NODE)
  docker logs -t -f $NODE > $FOLDER/node-$INDEX.log 2>&1 &
  docker logs -t -f $NODE_METRICS > $FOLDER/node-metrics-$INDEX.log 2>&1 &
  NODES[$INDEX]=$NODE
  let INDEX=INDEX+1
done
sleep 2

declare -a REPEATERS

INDEX=0
while [ $INDEX -lt $REPEATER_COUNT ]; do
  echo Starting Repeater $INDEX
  ./test-repeat.sh $HUB_NAME $TESTS_PER_REPEATER $INDEX $BROWSER &
  REPEATERS[$INDEX]=$!
  let INDEX=INDEX+1
done

INDEX=0
while [ $INDEX -lt $REPEATER_COUNT ]; do
  echo Waiting for Repeater $INDEX
  wait ${REPEATERS[$INDEX]}
  let INDEX=INDEX+1
done

INDEX=0
while [ $INDEX -lt $NODE_COUNT ]; do
  echo Stopping Node $INDEX
  NODE=${NODES[$INDEX]}
  docker rm -f $NODE > /dev/null 2>&1 &
  let INDEX=INDEX+1
done

echo Stopping Hub
docker rm -f $HUB > /dev/null 2>&1 &

wait

RESULTS=$FOLDER/results.txt

echo -----------------------------------------   > $RESULTS
echo Summary:                                    >> $RESULTS
echo -----------------------------------------   >> $RESULTS
echo "Repeaters:          $REPEATER_COUNT"       >> $RESULTS
echo "Tests per Repeater: $TESTS_PER_REPEATER"   >> $RESULTS
echo -----------------------------------------   >> $RESULTS
echo -----------------------------------------   >> $RESULTS

INDEX=0
while [ $INDEX -lt $REPEATER_COUNT ]; do
  echo Repeater $INDEX                           >> $RESULTS
  sed 's/^/   /' $FOLDER/$INDEX/results.txt      >> $RESULTS
  echo ----------------------------------------- >> $RESULTS
  let INDEX=INDEX+1
done

cat $RESULTS
