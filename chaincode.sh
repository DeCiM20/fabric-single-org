#!/bin/bash
set -e

# Usage:
#   $0 {package|install|installed|approve|approved|readiness|commit} <ORG_NUMBER> [PACKAGE_ID]
if [ $# -lt 2 ]; then
  echo "❌ Usage: $0 {package|install|installed|approve|approved|readiness|commit} <ORG_NUMBER> [PACKAGE_ID]"
  exit 1
fi

CMD="$1"; shift
ORG="$1"; shift

# Calculate peer port: Org1=7051, Org2=8051, Org3=9051, etc.
calc_peer_port() {
  local org="$1"
  echo $((7051 + (org - 1) * 1000))
}

# Common environment for peer CLI
PORT=$(calc_peer_port "$ORG")
PEER_ADDRESS="peer0.org${ORG}.example.com:${PORT}" # Peer with the chaincode

# MSP envs
CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org${ORG}.example.com/msp"
CORE_PEER_ADDRESS="peer0.org$ORG.example.com:${PORT}"
CORE_PEER_LOCALMSPID="Org${ORG}MSP"
  

# Fixed chaincode parameters
PKG_PATH="/opt/home/chaincode/packaged/test-contract-2_1.0.0.tar.gz"
RAW_PATH="/opt/home/chaincode/raw/golang/test-contract-2"
CHANNEL="my-channel"
NAME="test-contract-2"
VERSION="1.0.0"
SEQUENCE=1

ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

function package() {
  docker exec ${CLI_CONTAINER} peer lifecycle chaincode package ${PKG_PATH} --path ${RAW_PATH} --lang golang --label ${NAME}_${VERSION}
}

function install() {
  docker exec $ENV cli peer lifecycle chaincode install ${PKG_PATH} --peerAddresses ${PEER_ADDRESS}
}

function installed() {
  docker exec $ENV cli peer lifecycle chaincode queryinstalled
}

function approve() {
  local PKG_ID="$1"
  docker exec $ENV cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID ${CHANNEL} --name ${NAME} --version ${VERSION} --package-id ${PKG_ID} --sequence ${SEQUENCE} --peerAddresses ${PEER_ADDRESS}
}

function approved() {
  docker exec $ENV cli peer lifecycle chaincode queryapproved --channelID ${CHANNEL} --name ${NAME} --output json
}

function readiness() {
  docker exec $ENV cli peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL} --name ${NAME} --version ${VERSION} --sequence ${SEQUENCE} --output json
}

function commit() {
  docker exec $ENV cli peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID ${CHANNEL} --name ${NAME} --version ${VERSION} --sequence ${SEQUENCE} --peerAddresses ${PEER_ADDRESS}
}

# Dispatch
case "${CMD}" in
  package|install|installed|approved|readiness|commit)
    $CMD ${1:+$1}
    ;;
  approve)
    # approve needs PACKAGE_ID as $1
    [ -n "$1" ] || { echo "❌ approve requires <PACKAGE_ID>"; exit 1; }
    approve "$1"
    ;;
  *)
    echo "❌ Unknown command: ${CMD}" >&2
    echo "Usage: $0 {package|install|installed|approve|approved|readiness|commit} <ORG_NUMBER> [PACKAGE_ID]"
    exit 1
    ;;
esac
