#!/bin/bash
COUNTER=0
HUB_NAME=$1
TEST_COUNT=$2
REPEATER=$3
BROWSER=$4
ROOT_FOLDER=$5

if [ -z $HUB_NAME ]; then
  echo Must provide hub name
  exit 1
fi

if [ -z $TEST_COUNT ]; then
  TEST_COUNT=5
fi

if [ -z $REPEATER ]; then
  REPEATER=0
fi

if [ -z $BROWSER ]; then
  BROWSER=chrome
fi

if [ -z $ROOT_FOLDER ]; then
  ROOT_FOLDER=stress-logs
fi

FOLDER=$ROOT_FOLDER/$REPEATER

mkdir -p $FOLDER

declare -a SUMMARY

INDEX=0
while [ $INDEX -lt $TEST_COUNT ]; do
  NODE=$(docker run -d --link $HUB_NAME:hub selenium/test:local node smoke-$BROWSER.js)
  docker logs -f $NODE > $FOLDER/test-$INDEX.log 2>&1 &
  SUMMARY[$INDEX]=$(docker wait $NODE)
  docker rm -f $NODE > /dev/null 2>&1 &
  let INDEX=INDEX+1
done

wait

RESULTS=$FOLDER/results.txt

INDEX=0
while [ $INDEX -lt $TEST_COUNT ]; do
  STATUS=${SUMMARY[$INDEX]}
  RESULT=PASSED

  if [ $STATUS -ne 0 ]; then
    RESULT=FAILED
  fi

  echo Test $INDEX: $RESULT >> $RESULTS
  let INDEX=INDEX+1
done
