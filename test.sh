#!/bin/bash
set -xe
DATA_DIR=./test

# Preparing the image
docker-compose build ssync

# # Cleaning up
function clean_up() {
  docker-compose down -v 2> /dev/null
  rm -rf ${DATA_DIR}
  mkdir -p ${DATA_DIR}
}

function start_services() {
  docker-compose up -d
  sleep 0.5
  docker-compose ps
}

# Simple test run
clean_up
echo 123 > ${DATA_DIR}/test.file
docker-compose run ssync run
RESULT=$(docker-compose run app cat test.file | tr -d '\r')
[ $RESULT -eq 123 ]

# Watch test
clean_up
start_services
echo 456 > ${DATA_DIR}/test.file
sleep 0.1
RESULT=$(docker-compose run app cat test.file | tr -d '\r')
[ $RESULT -eq 456 ]

# UID Rests
clean_up
export SYNC_UID=1000
echo 0 > ${DATA_DIR}/test.file
docker-compose run ssync run
docker-compose run app find -user 1000 | grep test.file

echo "All tests completed sucessfully"
echo -n "Cleanin up..."
clean_up
echo "Done"
