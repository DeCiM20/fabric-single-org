#!/bin/bash
set -e

CORE_PEER_ADDRESS="peer0.org1.example.com:7051"

function start() {
  echo "🔧 Generating certs...."
  ./crypto.sh

  echo "🚀 Starting CLI container...."
  docker-compose -f docker-compose-cli.yaml up -d

  echo "🔨 Generating artifacts...."
  ./artifacts.sh

  sleep 10

  echo "🌐 Starting network container...."
  docker-compose -f docker-compose.yaml up -d

  sleep 10

  echo "🔗 Running channel.sh...."
  ./channel.sh
  echo "🎉 Network is up and ready!"
}

function stop() {
  echo "🧹 Cleaning up network..."
  docker-compose -f docker-compose.yaml down --volumes --remove-orphans
  docker-compose -f docker-compose-cli.yaml down --volumes --remove-orphans
  rm -rf crypto artifacts
}

function channels() {
  local cmd="docker exec -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS cli peer channel list"
  echo "Running: $cmd"
  eval "$cmd"
}

function printHelp() {
    echo "Usage: ./network.sh start|stop|restart"
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  channels)
    channels
    ;;
  restart)
    start
    stop
    ;;
  *)
    printHelp
    ;;
esac
