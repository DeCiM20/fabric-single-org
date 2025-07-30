#!/bin/bash
set -e

# Usage: ./channel.sh <ORG_NUMBER>
if [ -z "$1" ]; then
  echo "❌ Usage: $0 <ORG_NUMBER>"
  exit 1
fi

ORG="$1"

CLI_CONTAINER="org${ORG}_cli"

CHANNEL_NAME="my-channel"
ARTIFACTS_DIR="/opt/home/artifacts"

CORE_PEER_MSPCONFIGPATH="/opt/home/org1/users/Admin@org1.example.com/msp"
CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
CORE_PEER_LOCALMSPID="Org1MSP"

ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

function createChannel() {
  echo "📡 Creating channel '${CHANNEL_NAME}'..."
  docker exec $ENV cli peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f ${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx --outputBlock ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block # --tls --cafile /opt/home/orderer/tls/ca.crt
  echo "✅ Channel '${CHANNEL_NAME}' created successfully."
}

function joinChannel() {
  echo ">>> peer0.org${ORG}.example.com joining channel '${CHANNEL_NAME}'"
  docker exec $ENV cli peer channel join -b ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block
  echo "✅ peer0.org${ORG}.example.com joined the channel."
}

function updateAnchorPeers() {
  CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org$ORG.example.com/msp"
  local PORT=$((7051 + (ORG - 1) * 1000))
  CORE_PEER_ADDRESS="peer0.org$ORG.example.com:${PORT}"
  CORE_PEER_LOCALMSPID="Org${ORG}MSP"

  echo "🧭 Updating anchor peers..."
  docker exec $ENV cli peer channel update -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f ${ARTIFACTS_DIR}/Org${ORG}anchors.tx
  echo "🔄 Anchor peer updated for Org${ORG}"
}

function joinExistingChannel() {
  CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org$ORG.example.com/msp"
  local PORT=$((7051 + (ORG - 1) * 1000))
  CORE_PEER_ADDRESS="peer0.org$ORG.example.com:${PORT}"
  CORE_PEER_LOCALMSPID="Org${ORG}MSP"

  echo ">>> Getting the initial block for channel $CHANNEL_NAME ..."
  docker exec $ENV cli peer channel fetch config $ARTIFACTS_DIR/${CHANNEL_NAME}block.pb -o orderer.example.com:7050 -c ${CHANNEL_NAME}

  echo ">>> peer0.org${ORG}.example.com joining channel '${CHANNEL_NAME}'"
  docker exec $ENV cli peer channel join -b ${ARTIFACTS_DIR}/${CHANNEL_NAME}block.pb
  echo "✅ peer0.org${ORG}.example.com joined the channel."
}

# Only create channel with org1
if [ "$ORG" -eq 1 ]; then
  createChannel
  joinChannel
else
  echo "▶️ Detected Org${ORG} – will skip channel creation"
  joinExistingChannel
fi

# updateAnchorPeers