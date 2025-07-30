#!/bin/bash
set -e

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

  echo "🔗 Running channel.sh for Org1...."
  ./channel.sh 1
  echo "🎉 Network is up and ready!"
}

function stop() {
  echo "🧹 Cleaning up network..."
  docker-compose -f docker-compose.yaml down --volumes --remove-orphans
  docker-compose -f docker-compose-cli.yaml down --volumes --remove-orphans
  rm -rf crypto artifacts
}

function channels() {
  if [ -z "$1" ]; then
    echo "❌ Usage: $0 channels <ORG_NUMBER>"
    exit 1
  fi

  local ORG="$1"
  local PORT=$((7051 + (ORG - 1) * 1000))

  local CORE_PEER_ADDRESS="peer0.org${ORG}.example.com:${PORT}"
  local CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org${ORG}.example.com/msp"
  local CORE_PEER_LOCALMSPID="Org${ORG}MSP"
  
  echo "👉 Listing channels for Org${ORG} (${PEER_ADDRESS})"
  docker exec -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer channel list
}

function printHelp() {
  echo "Usage: $0 {start|stop|restart|channels [ORG_NUMBER]}"
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  channels)
    shift
    channels "$@"
    ;;
  restart)
    start
    stop
    ;;
  *)
    printHelp
    ;;
esac
