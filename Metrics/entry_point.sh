#!/bin/bash
CID=$1
FOLDER=/metrics/$CID

DONE=0

function shutdown {
  DONE=1
}

awk '{ print $1 }' $FOLDER/memory.stat | tr '\n' ',' | sed 's/,$/\n/'

trap shutdown TERM INT

while [ -d $FOLDER ] && [ $DONE -eq 0 ]; do
  awk '{ print $2 }' $FOLDER/memory.stat | tr '\n' ',' | sed 's/,$/\n/'
  sleep 1
done
